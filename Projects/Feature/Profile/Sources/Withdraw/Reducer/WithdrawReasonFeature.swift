//
//  WithdrawReasonFeature.swift
//  Profile
//

import Foundation

import AuthDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import DeviceServiceInterface
import PickeAuthInterface

@Reducer
public struct WithdrawReasonFeature {
  public init() {}

  /// 탈퇴 사유 — picke.pen 순서.
  public enum Reason: String, CaseIterable, Equatable, Identifiable {
    case notFrequent = "자주 이용하지 않아요"
    case noTopic = "보고 싶은 배틀 주제가 없어요"
    case notFit = "배틀 방식이 제게 잘 맞지 않아요"
    case inconvenient = "서비스 이용이 불편해요"
    case noTime = "이용할 시간이 없어요"

    public var id: String { rawValue }

    /// 서버 reason enum 코드 (Android SettingViewModel 매핑과 동일).
    public var serverCode: String {
      switch self {
      case .notFrequent: return "NOT_USED_OFTEN"
      case .noTopic: return "NO_INTERESTING_BATTLES"
      case .notFit: return "BATTLE_STYLE_NOT_FIT"
      case .inconvenient: return "SERVICE_INCONVENIENT"
      case .noTime: return "NO_TIME"
      }
    }
  }

  @ObservableState
  public struct State: Equatable {
    public var nickname: String
    public var selectedReason: Reason?
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
    case reasonTapped(Reason)
    case submitTapped
    case backTapped
  }

  public enum AsyncAction: Equatable {
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
    /// 픽케로 다시 돌아가기 → 설정으로 복귀.
    case dismiss
    /// 탈퇴 완료 → 로그인 화면으로.
    case sessionEnded
  }

  nonisolated enum CancelID: Hashable {
    case withdraw
  }

  @Dependency(\.authUseCase) private var authUseCase
  @Dependency(\.authService) private var authService
  @Dependency(\.deviceUseCase) private var deviceUseCase

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

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension WithdrawReasonFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case let .reasonTapped(reason):
      // 단일 선택 — 같은 항목 재탭 시 해제.
      state.selectedReason = (state.selectedReason == reason) ? nil : reason
      return .none

    case .submitTapped:
      // 제출하기 → 영구 삭제 확인 팝업 → 확인 시 탈퇴 진행.
      state.customAlert = .withdraw()
      return .none

    case .backTapped:
      return .send(.delegate(.dismiss))
    }
  }

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
    switch action {
    case let .customAlert(alertAction):
      switch alertAction {
      case .presented(.confirmTapped):
        state.customAlert = nil
        return .send(.async(.performWithdraw))

      case .presented(.cancelTapped):
        state.customAlert = nil
        return .none

      case .dismiss:
        state.customAlert = nil
        return .none
      }
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .performWithdraw:
      guard !state.isProcessing else { return .none }
      state.isProcessing = true
      let reason = (state.selectedReason ?? .notFrequent).serverCode
      return .run { [deviceUseCase] send in
        // Keychain 초기화 전(인증 유효) 에 디바이스 토큰 해제.
        if let deviceToken = DeviceTokenStorage.token, !deviceToken.isEmpty {
          try? await deviceUseCase.unregisterDevice(fcmToken: deviceToken)
        }
        do {
          _ = try await authUseCase.withDraw(reason: reason)
        } catch {
          Log.error("[WithdrawReasonFeature] withdraw failed: \(error.localizedDescription)")
        }
        await send(.inner(.sessionCleared))
      }
      .cancellable(id: CancelID.withdraw, cancelInFlight: true)
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
      let authService = authService
      return .run { send in
        await authService.signOut()
        await send(.delegate(.sessionEnded))
      }
    }
  }
}
