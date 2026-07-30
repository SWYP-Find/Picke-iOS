//
//  AppHomeCoordinator.swift
//  Picke
//

import Foundation

import ComposableArchitecture
import PickeDesignKit
import Presentation
import PickeCore
import TCAFlow
import AudioPlayerServiceInterface

@FlowCoordinator(screen: "AppHomeScreen", navigation: true)
public struct AppHomeCoordinator {
  public init() {}

  @Dependency(\.audioPlayer) private var audioPlayer

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
