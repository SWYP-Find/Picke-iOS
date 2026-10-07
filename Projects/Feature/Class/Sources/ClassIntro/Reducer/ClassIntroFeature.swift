//
//  ClassIntroFeature.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI

@Reducer
public struct ClassIntroFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents public var join: ClassJoinFeature.State?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case join(PresentationAction<ClassJoinFeature.Action>)
    case customAlert(PresentationAction<CustomAlertAction>)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case joinTapped
    case myClassesTapped
    case createTapped
    case ticketTapped
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case nicknameModalPresented(ClassRoom)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case backToHome
    case joined(ClassRoom, nickname: String)
    case myClasses
    case create
    case ticket
  }

  nonisolated enum CancelID: Hashable {
    case nicknameModal
  }

  @Dependency(\.continuousClock) private var clock

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        // 이름 입력 모달 대기 중 다른 탭이 들어오면 예약된 모달을 취소한다.
        return .merge(
          .cancel(id: CancelID.nicknameModal),
          handleViewAction(
            state: &state,
            action: viewAction
          )
        )

      case let .join(presentationAction):
        return handleJoinAction(
          state: &state,
          action: presentationAction
        )

      case .customAlert(.presented(.confirmTapped)),
           .customAlert(.presented(.cancelTapped)),
           .customAlert(.dismiss):
        state.customAlert = nil
        return .none

      case .customAlert:
        return .none

      case let .inner(innerAction):
        return handleInnerAction(
          state: &state,
          action: innerAction
        )

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$join, action: \.join) {
      ClassJoinFeature()
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension ClassIntroFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.backToHome))

    case .joinTapped:
      state.join = .init()
      return .none

    case .myClassesTapped:
      return .send(.delegate(.myClasses))

    case .createTapped:
      return .send(.delegate(.create))

    case .ticketTapped:
      state.customAlert = .alert(
        title: "이용권 등록 준비 중",
        message: "이용권 등록 기능은 아직 사용할 수 없습니다.",
        cancelTitle: ""
      )
      return .none
    }
  }

  private func handleJoinAction(
    state: inout State,
    action: PresentationAction<ClassJoinFeature.Action>
  ) -> Effect<Action> {
    switch action {
    case .presented(.delegate(.dismiss)):
      state.join = nil
      return .none

    case let .presented(.delegate(.found(room))):
      state.join = nil
      // PickeModal exit 애니메이션(0.3초)이 끝난 뒤 이름 입력 모달을 새로 띄운다.
      return .run { [clock] send in
        try await clock.sleep(for: .seconds(0.3))
        await send(.inner(.nicknameModalPresented(room)))
      }
      .cancellable(id: CancelID.nicknameModal, cancelInFlight: true)

    case let .presented(.delegate(.joined(room, nickname: nickname))):
      state.join = nil
      return .send(.delegate(.joined(room, nickname: nickname)))

    case .presented, .dismiss:
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .nicknameModalPresented(room):
      state.join = .init(mode: .nickname, preview: room)
      return .none
    }
  }
}
