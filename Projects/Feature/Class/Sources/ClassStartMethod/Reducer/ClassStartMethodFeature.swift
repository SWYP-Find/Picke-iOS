//
//  ClassStartMethodFeature.swift
//  Class
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
        switch viewAction {
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

      case .delegate:
        return .none
      }
    }
  }
}
