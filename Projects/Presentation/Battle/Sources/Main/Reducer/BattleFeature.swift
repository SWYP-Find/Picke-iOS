//
//  BattleFeature.swift
//  Battle
//
//  빠른 배틀 탭 루트 기능. 오늘의 배틀 / 추천 배틀 진입.
//  GET /api/v1/battles (예정)
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro

@Reducer
public struct BattleFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false

    public init() {}
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case battleTapped(battleId: Int)
  }

  public enum AsyncAction: Equatable {
    case fetchRequested
  }

  public enum InnerAction: Equatable {}

  public enum DelegateAction: Equatable {
    case openBattle(battleId: Int)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case .async, .inner:
        return .none

      case .delegate:
        return .none
      }
    }
  }
}

extension BattleFeature {
  private func handleViewAction(
    state _: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .send(.async(.fetchRequested))

    case let .battleTapped(battleId):
      return .send(.delegate(.openBattle(battleId: battleId)))
    }
  }
}
