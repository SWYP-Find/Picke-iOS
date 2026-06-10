//
//  SettingsFeature.swift
//  Profile
//
//  설정 — picke.pen `설정`.
//  메뉴(알림설정/개인정보 처리방침/서비스 약관/로그아웃/회원 탈퇴) + 로그아웃·탈퇴 확인 팝업.
//  팝업은 DesignSystem 의 CustomAlert(.logout/.withdraw) 사용.
//  로그아웃/탈퇴 시 AuthUseCase 호출 → Keychain 초기화 → 로그인 화면 복귀.
//

import Foundation

import ComposableArchitecture
import DesignSystem
import Entity
import LogMacro
import UseCase

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
    case withdraw
  }

  @ObservableState
  public struct State: Equatable {
    public var menuItems: [MenuItem] = MenuItem.allCases
    public var pending: PendingAction?
    public var isProcessing: Bool = false
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init() {}
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
    case performWithdraw
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
    /// 로그아웃/탈퇴 완료 → 로그인 화면으로.
    case sessionEnded
  }

  nonisolated enum CancelID: Hashable {
    case auth
  }

  @Dependency(\.authUseCase) private var authUseCase
  @Dependency(\.keychainManager) private var keychainManager
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
        state.pending = .logout
        state.customAlert = .logout()
        return .none
      case .withdraw:
        state.pending = .withdraw
        state.customAlert = .withdraw()
        return .none
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
      @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
      let provider = userSession.provider.rawValue
      return .run { [analyticsUseCase] send in
        do {
          _ = try await authUseCase.logout()
        } catch {
          Log.error("[SettingsFeature] logout failed: \(error.localizedDescription)")
        }
        analyticsUseCase.track(.session(.logoutSucceeded, SessionEventData(provider: provider)))
        await send(.inner(.sessionCleared))
      }
      .cancellable(id: CancelID.auth, cancelInFlight: true)

    case .performWithdraw:
      guard !state.isProcessing else { return .none }
      state.isProcessing = true
      let token = keychainManager.refreshToken() ?? keychainManager.accessToken() ?? ""
      return .run { send in
        do {
          _ = try await authUseCase.withDraw(token: token)
        } catch {
          Log.error("[SettingsFeature] withdraw failed: \(error.localizedDescription)")
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
          case .withdraw:
            return .send(.async(.performWithdraw))
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
    case .sessionEnded:
      return .none
    }
  }
}
