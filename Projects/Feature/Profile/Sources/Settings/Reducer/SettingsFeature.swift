//
//  SettingsFeature.swift
//  Profile
//

import Foundation

import AuthDomainInterface
import ComposableArchitecture
import LogMacro
import PickeDesignKit
import PickeSharedUI
import PickeAnalyticsInterface
import DeviceServiceInterface
import PickeStorageInterface

@Reducer
public struct SettingsFeature {
  public init() {}

  public enum MenuItem: String, CaseIterable, Equatable, Identifiable {
    case notification = "알림설정"
    case privacy = "개인정보 처리방침"
    case terms = "서비스 약관"
    case logout = "로그아웃"
    case withdraw = "회원 탈퇴"

    public var id: String { rawValue }
  }

  /// 확인 팝업 대기 동작 (confirm 시 무엇을 실행할지).
  public enum PendingAction: Equatable {
    case logout
  }

  @ObservableState
  public struct State: Equatable {
    public var nickname: String
    public var menuItems: [MenuItem] = MenuItem.allCases
    public var pending: PendingAction?
    public var isProcessing: Bool = false
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init(nickname: String = "") {
      self.nickname = nickname
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case scope(ScopeAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case menuTapped(MenuItem)
  }

  public enum AsyncAction: Equatable {
    case performLogout
  }

  public enum InnerAction: Equatable {
    case sessionCleared
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openNotificationSettings
    case openPrivacy
    case openTerms
    /// 회원 탈퇴 → 탈퇴 사유 화면으로.
    case openWithdraw(nickname: String)
    /// 로그아웃/탈퇴 완료 → 로그인 화면으로.
    case sessionEnded
  }

  nonisolated enum CancelID: Hashable {
    case auth
  }

  @Dependency(\.authUseCase) private var authUseCase
  @Dependency(\.keychainManager) private var keychainManager
  @Dependency(\.deviceUseCase) private var deviceUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

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

      case let .scope(scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension SettingsFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .menuTapped(item):
      switch item {
      case .notification:
        return .send(.delegate(.openNotificationSettings))
      case .privacy:
        return .send(.delegate(.openPrivacy))
      case .terms:
        return .send(.delegate(.openTerms))
      case .logout:
        analyticsUseCase.track(.uiAction(action: .settingsLogout, screen: .settings))
        state.pending = .logout
        state.customAlert = .logout()
        return .none
      case .withdraw:
        analyticsUseCase.track(.uiAction(action: .settingsWithdraw, screen: .settings))
        return .send(.delegate(.openWithdraw(nickname: state.nickname)))
      }
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .performLogout:
      guard !state.isProcessing else { return .none }
      state.isProcessing = true
      return .run { [deviceUseCase] send in
        // Keychain 초기화 전(인증 유효) 에 디바이스 토큰 해제.
        if let token = DeviceTokenStorage.token, !token.isEmpty {
          try? await deviceUseCase.unregisterDevice(fcmToken: token)
        }
        do {
          _ = try await authUseCase.logout()
        } catch {
          Log.error("[SettingsFeature] logout failed: \(error.localizedDescription)")
        }
        await send(.inner(.sessionCleared))
      }
      .cancellable(id: CancelID.auth, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .sessionCleared:
      state.isProcessing = false
      // 서버 호출 성공/실패와 무관하게 로컬 세션은 정리하고 로그인으로 전환.
      keychainManager.clear()
      // 계정 분리 — Mixpanel distinct_id/슈퍼프로퍼티 초기화(다음 유저와 혼선 방지).
      analyticsUseCase.reset()
      return .send(.delegate(.sessionEnded))
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case let .customAlert(alertAction):
      switch alertAction {
      case let .presented(customAlertAction):
        switch customAlertAction {
        case .confirmTapped:
          let pending = state.pending
          state.pending = nil
          state.customAlert = nil
          switch pending {
          case .logout:
            return .send(.async(.performLogout))
          case .none:
            return .none
          }

        case .cancelTapped:
          state.pending = nil
          state.customAlert = nil
          return .none
        }

      case .dismiss:
        state.pending = nil
        state.customAlert = nil
        return .none
      }
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss:
      return .none
    case .openNotificationSettings:
      return .none
    case .openPrivacy:
      return .none
    case .openTerms:
      return .none
    case .openWithdraw:
      return .none
    case .sessionEnded:
      return .none
    }
  }
}
