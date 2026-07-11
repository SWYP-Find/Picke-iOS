//
//  AppBattleCoordinator.swift
//  Picke
//
//  App 레이어의 빠른 배틀 탭 조립 코디네이터.
//

import Foundation

import ComposableArchitecture
import DesignSystem
import Presentation
import Shared
import TCAFlow

@FlowCoordinator(screen: "AppBattleScreen", navigation: true)
public struct AppBattleCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<AppBattleScreen.State>]

    public init() {
      routes = [.root(.battle(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<AppBattleScreen>)
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

private extension AppBattleCoordinator {
  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AppBattleScreen>
  ) -> Effect<Action> {
    switch action {
    case let .routeAction(_, action: .battle(.delegate(.openBattle(battleId)))):
      state.routes.push(.chatRoom(.init(route: .init(battleId: battleId))))
      return .none

    case .routeAction(_, action: .chatRoom(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .chatRoom(.delegate(.requestFinalVote(battleId)))):
      guard FeatureFlag.isVotingEnabled else {
        return .run { _ in
          await MainActor.run {
            ToastManager.shared.showInfo(FeatureFlag.votingDisabledMessage)
          }
        }
      }
      state.routes.push(.chat(.init(route: .preVote(battleId: battleId))))
      return .none

    case .routeAction(_, action: .chat(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .chat(.delegate(.popToRoot))):
      return .send(.view(.backToRootAction))

    default:
      return .none
    }
  }

  func handleViewAction(
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
extension AppBattleCoordinator {
  @Reducer
  public enum AppBattleScreen {
    case battle(BattleFeature)
    case chatRoom(ChatRoomFeature)
    case chat(ChatCoordinator)
  }
}

// swiftformat:enable extensionAccessControl

extension AppBattleCoordinator.AppBattleScreen.State: Equatable {}
