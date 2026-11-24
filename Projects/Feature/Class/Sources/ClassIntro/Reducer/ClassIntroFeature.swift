//
//  ClassIntroFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
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
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?
    public var ticketNotice: ClassCreateTicketNotice?
    public var isCheckingTicket = false
    public var toastMessage: String?

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
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
    case toastShown
  }

  @CasePathable
  public enum InnerAction: Equatable {
    case ticketResponse(Result<ClassTicket, ClassTicketError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case backToHome
    case join
    case myClasses
    case create
    case ticket
    case registerTicket
  }

  public enum CancelID: Hashable, Sendable {
    case ticketCheck
  }

  @Dependency(\.classTicketUseCase) private var ticketUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .customAlert(alertAction):
        return handleCustomAlertAction(state: &state, action: alertAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.customAlert) {
      CustomConfirmAlert()
    }
  }
}

// MARK: - Action Handlers

extension ClassIntroFeature {
  private func handleCustomAlertAction(
    state: inout State,
    action: PresentationAction<CustomAlertAction>
  ) -> Effect<Action> {
    switch action {
    case .presented(.confirmTapped):
      let notice = state.ticketNotice
      clearTicketNotice(state: &state)
      return notice == .expired ? .send(.delegate(.registerTicket)) : .none
    case .presented(.cancelTapped), .dismiss:
      clearTicketNotice(state: &state)
      return .none
    case .presented:
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return cancelTicketCheck(state: &state, then: .send(.delegate(.backToHome)))

    case .joinTapped:
      return cancelTicketCheck(state: &state, then: .send(.delegate(.join)))

    case .myClassesTapped:
      return cancelTicketCheck(state: &state, then: .send(.delegate(.myClasses)))

    case .createTapped:
      // Android와 같이 만들기 전에 내 이용권 상태를 확인한다. 확인 중 다시 누르면 무시한다.
      guard !state.isCheckingTicket else { return .none }
      state.isCheckingTicket = true
      return .run { [ticketUseCase] send in
        let result: Result<ClassTicket, ClassTicketError> = await Result {
          try await ticketUseCase.fetchMyTicket()
        }
        .mapError { ($0 as? ClassTicketError) ?? .network($0.localizedDescription) }
        await send(.inner(.ticketResponse(result)))
      }
      .cancellable(id: CancelID.ticketCheck, cancelInFlight: true)

    case .ticketTapped:
      return cancelTicketCheck(state: &state, then: .send(.delegate(.ticket)))

    case .toastShown:
      state.toastMessage = nil
      return .none
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .ticketResponse(result):
      guard state.isCheckingTicket else { return .none }
      state.isCheckingTicket = false
      switch result {
      case let .success(ticket):
        switch ticket.status {
        case .active:
          return .send(.delegate(.create))
        case .expired:
          presentTicketNotice(.expired, state: &state)
        }
      case .failure(.notFound):
        presentTicketNotice(.required, state: &state)
      case .failure:
        state.toastMessage = "정보를 불러오지 못했어요"
      }
      return .none
    }
  }

  /// 확인 중 다른 이동을 하면 늦은 응답이 화면을 쌓지 않도록 확인을 취소한다.
  private func cancelTicketCheck(
    state: inout State,
    then effect: Effect<Action>
  ) -> Effect<Action> {
    guard state.isCheckingTicket else { return effect }
    state.isCheckingTicket = false
    return .merge(.cancel(id: CancelID.ticketCheck), effect)
  }

  private func presentTicketNotice(
    _ notice: ClassCreateTicketNotice,
    state: inout State
  ) {
    state.ticketNotice = notice
    state.customAlert = notice.alert
  }

  private func clearTicketNotice(state: inout State) {
    state.ticketNotice = nil
    state.customAlert = nil
  }
}
