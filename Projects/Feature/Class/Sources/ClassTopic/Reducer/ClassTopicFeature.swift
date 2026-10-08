//
//  ClassTopicFeature.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassTopicFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var keyword: String = ""
    public var level: ClassAudienceLevel = .middle
    public var categories: [ClassCategory] = []

    public init() {}

    public var filter: ClassTopicFilter {
      ClassTopicFilter(
        keyword: keyword.trimmingCharacters(in: .whitespacesAndNewlines),
        level: level,
        categories: categories
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
    case levelTapped(ClassAudienceLevel)
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

    case let .levelTapped(level):
      state.level = level
      return .none

    case let .categoryTapped(category):
      if let index = state.categories.firstIndex(of: category) {
        state.categories.remove(at: index)
      } else if state.categories.count < 3 {
        state.categories.append(category)
      }
      return .none

    case .searchTapped:
      return .send(.delegate(.search(state.filter)))
    }
  }
}
