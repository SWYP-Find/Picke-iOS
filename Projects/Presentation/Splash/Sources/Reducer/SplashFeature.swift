//
//  SplashFeature.swift
//  Splash
//
//  Created by Wonji Suh  on 5/6/26.
//

import Foundation


import ComposableArchitecture
import LogMacro
import AnalyticsServiceInterface
import AppUpdateDomainInterface
import PickeStorageInterface

@Reducer
public struct SplashFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    var loading: Bool = true
    /// 앱 업데이트 안내 (기본 alert).
    @Presents var alert: AlertState<Action.Alert>?
    var appStoreUrl: String = ""

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case alert(PresentationAction<Alert>)
    case delegate(DelegateAction)

    @CasePathable
    public enum Alert: Equatable {
      case updateConfirmed
      case updateDeferred
    }
  }

  // MARK: - ViewAction

  @CasePathable
  public enum View {
    case onAppear
  }

  // MARK: - AsyncAction

  @CasePathable
  public enum AsyncAction: Equatable {
    case checkAppUpdate
  }

  // MARK: - InnerAction

  @CasePathable
  public enum InnerAction: Equatable {
    case checkAppUpdateResponse(Result<AppUpdateInfo?, AppUpdateError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case presentAuth
    case presentMainTab
  }

  nonisolated enum CancelID: Hashable {
    case checkAppUpdate
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.keychainManager) var keychainManager
  @Dependency(\.appUpdateUseCase) var appUpdateUseCase
  @Dependency(\.openURL) var openURL
  @Dependency(\.analyticsUseCase) var analyticsUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case let .alert(alertAction):
        return handleAlertAction(state: &state, action: alertAction)

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

extension SplashFeature {
  private func handleViewAction(
    state _: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .splash, referrer: nil))
      analyticsUseCase.track(.onboardingStep(step: .splash, provider: nil))
      return .run { send in
        try await clock.sleep(for: .seconds(1.2))
        await send(.async(.checkAppUpdate))
      }
    }
  }

  private func handleAsyncAction(
    state _: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .checkAppUpdate:
      return .run { [appUpdateUseCase] send in
        let result = await Result {
          try await appUpdateUseCase.checkForUpdate()
        }
        .mapError(AppUpdateError.from)
        await send(.inner(.checkAppUpdateResponse(result)))
      }
      .cancellable(id: CancelID.checkAppUpdate, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .checkAppUpdateResponse(result):
      switch result {
      case let .success(updateInfo):
        guard let updateInfo else {
          return navigateToNextScreen(state: &state)
        }
        state.appStoreUrl = updateInfo.appStoreUrl
        state.alert = Self.updateAlert(version: updateInfo.latestVersion)
        return .none

      case let .failure(error):
        Log.error("[Splash] 앱 업데이트 체크 실패: \(error.localizedDescription)")
        return navigateToNextScreen(state: &state)
      }
    }
  }

  private func handleAlertAction(
    state: inout State,
    action: PresentationAction<Action.Alert>
  ) -> Effect<Action> {
    switch action {
    case .presented(.updateConfirmed):
      // 지금 업데이트 → App Store 이동 (앱 이탈).
      return .run { [appStoreUrl = state.appStoreUrl] _ in
        if let url = URL(string: appStoreUrl) {
          await openURL(url)
        }
      }

    case .presented(.updateDeferred):
      // 나중에 → 다음 화면.
      return navigateToNextScreen(state: &state)

    case .dismiss:
      return .none
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .presentAuth, .presentMainTab:
      return .none
    }
  }

  private func navigateToNextScreen(state _: inout State) -> Effect<Action> {
    hasStoredCredential
      ? .send(.delegate(.presentMainTab))
      : .send(.delegate(.presentAuth))
  }

  private static func updateAlert(version: String) -> AlertState<Action.Alert> {
    AlertState {
      TextState("새로운 버전이 출시되었어요!")
    } actions: {
      ButtonState(action: .updateConfirmed) {
        TextState("지금 업데이트")
      }
      ButtonState(role: .cancel, action: .updateDeferred) {
        TextState("나중에 할게요")
      }
    } message: {
      TextState("새로운 버전 \(version)이 출시되었습니다!\n더 나은 경험을 위해 지금 업데이트하세요!")
    }
  }

  private var hasStoredCredential: Bool {
    guard
      let accessToken = keychainManager.accessToken(),
      let refreshToken = keychainManager.refreshToken()
    else {
      return false
    }
    return !accessToken.isEmpty && !refreshToken.isEmpty
  }
}
