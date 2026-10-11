//
//  ClassStartMethodFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture

@Reducer
public struct ClassStartMethodFeature {
  public init() {}

  public enum Method: Equatable {
    case existingContent
    case ownTopic
  }

  @ObservableState
  public struct State: Equatable {
    public var selectedMethod: Method = .existingContent

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case methodTapped(Method)
    case continueTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case existingContentSelected
    case ownTopicSelected
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - Action Handlers

extension ClassStartMethodFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .methodTapped(method):
      state.selectedMethod = method
      return .none

    case .continueTapped:
      switch state.selectedMethod {
      case .existingContent:
        return .send(.delegate(.existingContentSelected))
      case .ownTopic:
        return .send(.delegate(.ownTopicSelected))
      }
    }
  }
}
