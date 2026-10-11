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
    @Presents public var guide: ClassStartGuideFeature.State?

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case guide(PresentationAction<ClassStartGuideFeature.Action>)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case methodTapped(Method)
    case guideTapped(ClassStartGuideKind)
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

      case .guide(.presented(.dismissTapped)), .guide(.dismiss):
        state.guide = nil
        return .none

      case .guide:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$guide, action: \.guide) {
      ClassStartGuideFeature()
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
      if state.guide != nil {
        state.guide = nil
        return .none
      }
      return .send(.delegate(.dismiss))

    case let .methodTapped(method):
      guard state.guide == nil else { return .none }
      state.selectedMethod = method
      return .none

    case let .guideTapped(kind):
      guard state.guide == nil else { return .none }
      state.guide = .showing(kind)
      return .none

    case .continueTapped:
      guard state.guide == nil else { return .none }
      switch state.selectedMethod {
      case .existingContent:
        return .send(.delegate(.existingContentSelected))
      case .ownTopic:
        return .send(.delegate(.ownTopicSelected))
      }
    }
  }
}
