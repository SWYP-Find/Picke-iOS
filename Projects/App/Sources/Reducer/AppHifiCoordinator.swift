//
//  AppHifiCoordinator.swift
//  Picke
//
//  App 레이어의 Hi-Fi 탭 조립 코디네이터.
//

import Foundation

import ComposableArchitecture
import Presentation
import TCAFlow

@FlowCoordinator(screen: "AppHifiScreen", navigation: true)
public struct AppHifiCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<AppHifiScreen.State>]

    public init() {
      routes = [.root(.hifi(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<AppHifiScreen>)
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

private extension AppHifiCoordinator {
  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AppHifiScreen>
  ) -> Effect<Action> {
    switch action {
    case let .routeAction(_, action: .hifi(.delegate(.openBattle(battleId)))):
      state.routes.push(.chat(.init(route: .preVote(battleId: battleId))))
      return .none

    case .routeAction(_, action: .chat(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .chat(.delegate(.popToRoot))):
      return .send(.view(.backToRootAction))

    case .routeAction(_, action: .hifi(.delegate(.openNotification))):
      state.routes.push(.notification(.init(route: .inbox)))
      return .none

    case .routeAction(_, action: .notification(.delegate(.dismiss))):
      return .send(.view(.backAction))

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
extension AppHifiCoordinator {
  @Reducer
  public enum AppHifiScreen {
    case hifi(HifiFeature)
    case chat(ChatCoordinator)
    case notification(NotificationCoordinator)
  }
}

// swiftformat:enable extensionAccessControl

extension AppHifiCoordinator.AppHifiScreen.State: Equatable {}
