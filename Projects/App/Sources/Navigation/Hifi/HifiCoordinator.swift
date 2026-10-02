//
//  HifiCoordinator.swift
//  Picke
//

import Foundation

import AudioPlayerServiceInterface
import ComposableArchitecture
import FeatureAssembly
import TCAFlow

@FlowCoordinator(screen: "HifiScreen", navigation: true)
public struct HifiCoordinator {
  public init() {}

  @Dependency(\.audioPlayer) private var audioPlayer

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

private extension HifiCoordinator {
  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<HifiScreen>
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

    case let .updateRoutes(newRoutes):
      // 스와이프 뒤로가기로 채팅(오디오 재생) 루트가 스택에서 통째로 사라지면
      // 하위 리듀서 teardown 으로 자체 정지 가드가 실행되지 못하므로 여기서 정지한다.
      let hasAudioScreen = newRoutes.contains { route in
        if case .chat = route.screen { return true }
        return false
      }
      if !hasAudioScreen {
        return .run { [player = audioPlayer] _ in await player.pause() }
      }
      return .none

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
