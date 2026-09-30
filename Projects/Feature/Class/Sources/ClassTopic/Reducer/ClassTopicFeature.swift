//
//  ClassTopicFeature.swift
//  Class
//

import Foundation

import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassTopicFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var keyword: String = ""
    public var level: ClassAudienceLevel = .middle
    public var category: ClassCategory?

    public init() {}

    public var filter: ClassTopicFilter {
      ClassTopicFilter(
        keyword: keyword.trimmingCharacters(in: .whitespacesAndNewlines),
        level: level,
        category: category
      )
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case categoryTapped(ClassCategory)
    case searchTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case search(ClassTopicFilter)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case .delegate:
        return .none
      }
    }
  }
}

extension ClassTopicFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .categoryTapped(category):
      state.category = state.category == category ? nil : category
      return .none

    case .searchTapped:
      return .send(.delegate(.search(state.filter)))
    }
  }
}
