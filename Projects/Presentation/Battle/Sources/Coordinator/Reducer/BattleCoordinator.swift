//
//  BattleCoordinator.swift
//  Battle
//
//  빠른 배틀 탭 코디네이터. 루트는 BattleFeature, 배틀 진입 시 ChatCoordinator 로 push.
//

import Foundation

import Chat
import ComposableArchitecture
import DesignSystem
import Shared
import TCAFlow

@FlowCoordinator(screen: "BattleScreen", navigation: true)
public struct BattleCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<BattleScreen.State>]

    public init() {
      routes = [.root(.battle(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<BattleScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
  }

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {}
  public enum NavigationAction: Equatable {}

  func handleRoute(
    state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case let .router(routeAction):
      routerAction(state: &state, action: routeAction)
    case let .view(viewAction):
      handleViewAction(state: &state, action: viewAction)
    case .async, .inner, .navigation:
      .none
    }
  }
}

extension BattleCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<BattleScreen>
  ) -> Effect<Action> {
    switch action {
    // 오늘의 배틀에서 선택 후 입장 → ChatRoom(채팅방) 직접 진입.
    case let .routeAction(_, action: .battle(.delegate(.openBattle(battleId)))):
      state.routes.push(.chatRoom(.init(battleId: battleId)))
      return .none

    case .routeAction(_, action: .chatRoom(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 채팅방 다 들으면 → ChatCoordinator(초기 PreVote) 흐름으로 연결.
    case let .routeAction(_, action: .chatRoom(.delegate(.requestFinalVote(battleId)))):
      // QA-38: 투표 안정화 전까지 진입 차단. 플래그가 켜지면 기존 흐름 그대로 동작.
      guard FeatureFlag.isVotingEnabled else {
        return .run { _ in
          await MainActor.run {
            ToastManager.shared.showInfo(FeatureFlag.votingDisabledMessage)
          }
        }
      }
      state.routes.push(.chat(.init(battleId: battleId)))
      return .none

    case .routeAction(_, action: .chat(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .chat(.delegate(.popToRoot))):
      return .send(.view(.backToRootAction))

    default:
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backAction:
      state.routes.goBack()
      return .none
    case .backToRootAction:
      state.routes.goBackToRoot()
      return .none
    }
  }
}

// swiftformat:disable extensionAccessControl
extension BattleCoordinator {
  @Reducer
  public enum BattleScreen {
    case battle(BattleFeature)
    case chatRoom(ChatRoomFeature)
    case chat(ChatCoordinator)
  }
}

// swiftformat:enable extensionAccessControl

extension BattleCoordinator.BattleScreen.State: Equatable {}
