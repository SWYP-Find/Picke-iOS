//
//  AuthCoordinator.swift
//  Picke
//

import Foundation

import ComposableArchitecture
import FeatureAssembly
import TCAFlow

@FlowCoordinator(screen: "AuthScreen", navigation: true)
public struct AuthCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    var routes: [Route<AuthScreen.State>]

    public init() {
      routes = [.root(.login(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<AuthScreen>)
    case view(View)
    case navigation(NavigationAction)
  }

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }

  public enum NavigationAction: Equatable {
    case presentMainTab
  }

  func handleRoute(
    state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case let .router(routeAction):
      routerAction(state: &state, action: routeAction)

    case let .view(viewAction):
      handleViewAction(state: &state, action: viewAction)

    case .navigation:
      .none
    }
  }
}

private extension AuthCoordinator {
  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AuthScreen>
  ) -> Effect<Action> {
    switch action {
    case .routeAction(_, action: .login(.delegate(.presentOnboarding))):
      state.routes.push(.onboarding(.init()))
      return .none

    case .routeAction(_, action: .login(.delegate(.presentMainTab))):
      return .send(.navigation(.presentMainTab))

    case .routeAction(_, action: .onboarding(.delegate(.presentMainTab))):
      return .send(.navigation(.presentMainTab))

    case let .routeAction(_, action: .login(.delegate(.presentTermsWeb(urlString)))):
      state.routes.push(.web(.init(route: .init(url: urlString))))
      return .none

    case .routeAction(_, action: .web(.delegate(.backToRoot))):
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
extension AuthCoordinator {
  @Reducer
  public enum AuthScreen {
    case login(LoginFeature)
    case onboarding(OnBoardingFeature)
    case web(WebReducer)
  }
}

// swiftformat:enable extensionAccessControl

extension AuthCoordinator.AuthScreen.State: Equatable {}
