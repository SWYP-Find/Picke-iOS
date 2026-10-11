//
//  ClassClosedBattleFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassClosedBattleFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var room: ClassRoom

    public init(room: ClassRoom) {
      self.room = room
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
    case resultTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case openReport(ClassRoom)
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

extension ClassClosedBattleFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
    case .resultTapped:
      return .send(.delegate(.openReport(state.room)))
    }
  }
}
