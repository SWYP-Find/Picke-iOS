//
//  WithdrawReasonFeature.swift
//  Profile
//
//  회원 탈퇴 — picke.pen `탈퇴하기`.
//  탈퇴 사유(복수 선택) 수집 + 제출하기/돌아가기.
//  제출 시 AuthUseCase.withDraw 호출 → Keychain 초기화 → 세션 종료 전파.
//

import Foundation

import ComposableArchitecture
import AuthDomain
import PickeDesignKit
import LogMacro
import UseCase

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
  }

  @ObservableState
  public struct State: Equatable {
    public var nickname: String
    public var selectedReasons: Set<Reason> = []
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
  @Dependency(\.keychainManager) private var keychainManager
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
      if state.selectedReasons.contains(reason) {
        state.selectedReasons.remove(reason)
      } else {
        state.selectedReasons.insert(reason)
      }
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
      let token = keychainManager.refreshToken() ?? keychainManager.accessToken() ?? ""
      return .run { [deviceUseCase] send in
        // Keychain 초기화 전(인증 유효) 에 디바이스 토큰 해제.
        if let deviceToken = DeviceTokenStorage.token, !deviceToken.isEmpty {
          try? await deviceUseCase.unregisterDevice(fcmToken: deviceToken)
        }
        do {
          _ = try await authUseCase.withDraw(token: token)
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
      keychainManager.clear()
      return .send(.delegate(.sessionEnded))
    }
  }
}
