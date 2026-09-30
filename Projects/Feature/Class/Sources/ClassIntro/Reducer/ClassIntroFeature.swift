//
//  ClassIntroFeature.swift
//  Class
//

import Foundation

import ComposableArchitecture

@Reducer
public struct ClassIntroFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case joinTapped
    case myClassesTapped
    case createTapped
    case ticketTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case join
    case myClasses
    case create
    case ticket
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(
          state: &state,
          action: viewAction
        )

      case .delegate:
        return .none
      }
    }
  }
}

extension ClassIntroFeature {
  private func handleViewAction(
    state _: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .joinTapped:
      return .send(.delegate(.join))

    case .myClassesTapped:
      return .send(.delegate(.myClasses))

    case .createTapped:
      return .send(.delegate(.create))

    case .ticketTapped:
      return .send(.delegate(.ticket))
    }
  }
}
