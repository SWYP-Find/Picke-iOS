//
//  HifiCoordinator.swift
//  Hifi
//

import Foundation

import ComposableArchitecture
import TCAFlow

@FlowCoordinator(screen: "HifiScreen", navigation: true)
public struct HifiCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<HifiScreen.State>]

    public init() {
      routes = [.root(.hifi(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<HifiScreen>)
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

extension HifiCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<HifiScreen>
  ) -> Effect<Action> {
    switch action {
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
extension HifiCoordinator {
  @Reducer
  public enum HifiScreen {
    case hifi(HifiFeature)
  }
}

// swiftformat:enable extensionAccessControl

extension HifiCoordinator.HifiScreen.State: Equatable {}
