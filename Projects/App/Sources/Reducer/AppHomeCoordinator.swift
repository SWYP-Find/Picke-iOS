//
//  AppHomeCoordinator.swift
//  Picke
//
//  App 레이어의 홈 탭 조립 코디네이터.
//

import Foundation

import ComposableArchitecture
import DesignSystem
import Presentation
import Shared
import TCAFlow

@FlowCoordinator(screen: "AppHomeScreen", navigation: true)
public struct AppHomeCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<AppHomeScreen.State>]

    public init() {
      routes = [.root(.home(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<AppHomeScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
  }

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
    case openBattle(battleId: Int)
    case openPerspective(perspectiveId: Int, commentId: Int?)
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

private extension AppHomeCoordinator {
  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AppHomeScreen>
  ) -> Effect<Action> {
    switch action {
    case let .routeAction(_, action: .home(.delegate(.presentPreVote(battleId)))):
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

    case .routeAction(_, action: .home(.delegate(.openNotification))):
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

    case let .openBattle(battleId):
      state.routes.goBackToRoot()
      state.routes.push(.chat(.init(route: .preVote(battleId: battleId))))
      return .none

    case let .openPerspective(perspectiveId, commentId):
      state.routes.goBackToRoot()
      state.routes.push(.chat(.init(route: .perspective(
        perspectiveId: perspectiveId,
        commentId: commentId
      ))))
      return .none
    }
  }
}

// swiftformat:disable extensionAccessControl
extension AppHomeCoordinator {
  @Reducer
  public enum AppHomeScreen {
    case home(HomeFeature)
    case chat(ChatCoordinator)
    case notification(NotificationCoordinator)
  }
}

// swiftformat:enable extensionAccessControl

extension AppHomeCoordinator.AppHomeScreen.State: Equatable {}
