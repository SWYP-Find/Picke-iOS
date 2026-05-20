//
//  HomeCoordinator.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

import ComposableArchitecture
import TCAFlow

@FlowCoordinator(screen: "HomeScreen", navigation: true)
public struct HomeCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<HomeScreen.State>]

    public init() {
      routes = [.root(.home(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<HomeScreen>)
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

  func handleRoute(state: inout State, action: Action) -> Effect<Action> {
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

extension HomeCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<HomeScreen>
  ) -> Effect<Action> {
    switch action {
    case .routeAction(_, action: .home(.delegate(.presentPreVote))):
      state.routes.push(.preVote(.init()))
      return .none

    case .routeAction(_, action: .preVote(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .preVote(.delegate(.voteSubmitted(battleId, _)))):
      state.routes.push(.chatRoom(.init(battleId: battleId)))
      return .none

    case .routeAction(_, action: .chatRoom(.delegate(.dismiss))):
      return .send(.view(.backAction))

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
extension HomeCoordinator {
  @Reducer
  public enum HomeScreen {
    case home(HomeFeature)
    case preVote(PreVoteFeature)
    case chatRoom(ChatRoomFeature)
  }
}

// swiftformat:enable extensionAccessControl

extension HomeCoordinator.HomeScreen.State: Equatable {}
