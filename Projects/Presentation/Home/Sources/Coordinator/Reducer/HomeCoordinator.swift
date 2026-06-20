//
//  HomeCoordinator.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

import Chat
import ComposableArchitecture
import DesignSystem
import Notification
import Shared
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
    /// 딥링크(알림) → 배틀 상세(채팅) 진입.
    case openBattle(battleId: Int)
    /// 딥링크(알림) → 관점(답글) 화면 진입 (commentId 있으면 해당 답글로 스크롤).
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

extension HomeCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<HomeScreen>
  ) -> Effect<Action> {
    switch action {
    case let .routeAction(_, action: .home(.delegate(.presentPreVote(battleId)))):
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
      // 큐레이팅 X — 홈 루트로 복귀
      return .send(.view(.backToRootAction))

    // 알림(종) 아이콘 → 알림받기 화면 진입.
    case .routeAction(_, action: .home(.delegate(.openNotification))):
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
    case let .openBattle(battleId):
      // 중복 스택 방지 후 배틀(채팅) 상세 진입.
      state.routes.goBackToRoot()
      state.routes.push(.chat(.init(battleId: battleId)))
      return .none
    case let .openPerspective(perspectiveId, commentId):
      // 중복 스택 방지 후 관점(답글) 화면 진입.
      state.routes.goBackToRoot()
      state.routes.push(.chat(.init(perspectiveId: perspectiveId, commentId: commentId)))
      return .none
    }
  }
}

// swiftformat:disable extensionAccessControl
extension HomeCoordinator {
  @Reducer
  public enum HomeScreen {
    case home(HomeFeature)
    case chat(ChatCoordinator)
    case notification(NotificationCoordinator)
  }
}

// swiftformat:enable extensionAccessControl

extension HomeCoordinator.HomeScreen.State: Equatable {}
