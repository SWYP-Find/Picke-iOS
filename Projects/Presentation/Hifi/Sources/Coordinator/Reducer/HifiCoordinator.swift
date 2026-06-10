//
//  HifiCoordinator.swift
//  Hifi
//
//  Hi-Fi 탭 코디네이터. 루트는 HifiFeature, 후속 화면이 필요하면 HifiScreen 에 case 추가.
//

import Foundation

import Chat
import ComposableArchitecture
import Notification
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
    case let .routeAction(_, action: .hifi(.delegate(.openBattle(battleId)))):
      state.routes.push(.chat(.init(battleId: battleId)))
      return .none

    case .routeAction(_, action: .chat(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .chat(.delegate(.popToRoot))):
      // 큐레이팅 X — 탐색 루트로 복귀
      return .send(.view(.backToRootAction))

    // 알림(종) 아이콘 → 알림받기 화면 진입.
    case .routeAction(_, action: .hifi(.delegate(.openNotification))):
      state.routes.push(.notification(.init()))
      return .none

    // 알림받기 백탭 → 뒤로.
    case .routeAction(_, action: .notification(.delegate(.dismiss))):
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
extension HifiCoordinator {
  @Reducer
  public enum HifiScreen {
    case hifi(HifiFeature)
    case chat(ChatCoordinator)
    case notification(NotificationCoordinator)
  }
}

// swiftformat:enable extensionAccessControl

extension HifiCoordinator.HifiScreen.State: Equatable {}
