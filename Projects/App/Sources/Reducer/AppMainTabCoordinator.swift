//
//  AppMainTabCoordinator.swift
//  Picke
//
//  Created by Codex on 7/11/26.
//

import Foundation

import ComposableArchitecture
import DesignSystem
import Presentation
import TCAFlow

@Reducer
public struct AppMainTabCoordinator {
  public init() {}

  public enum Tab: Int, CaseIterable {
    case home
    case explore
    case quickBattle
    case myPage

    public var title: String {
      switch self {
      case .home: return "홈"
      case .explore: return "탐색"
      case .quickBattle: return "빠른 배틀"
      case .myPage: return "마이"
      }
    }

    public func iconAsset(isSelected: Bool) -> ImageAsset {
      switch self {
      case .home: return isSelected ? .tabHomeActive : .tabHome
      case .explore: return isSelected ? .tabExploreActive : .tabExplore
      case .quickBattle: return isSelected ? .tabQuickBattleActive : .tabQuickBattle
      case .myPage: return isSelected ? .tabMyPageActive : .tabMyPage
      }
    }
  }

  @ObservableState
  public struct State: Equatable {
    public var selectedTab: Int
    public var previousTab: Int = Tab.home.rawValue
    public var homeState: AppHomeCoordinator.State
    public var exploreState: AppHifiCoordinator.State
    public var quickBattleState: AppBattleCoordinator.State
    public var myPageState: AppProfileCoordinator.State

    public init(selectedTab: Int = Tab.home.rawValue) {
      self.selectedTab = selectedTab
      homeState = .init()
      exploreState = .init()
      quickBattleState = .init()
      myPageState = .init()
    }
  }

  @CasePathable
  public enum Action {
    case selectTab(Int)
    case tabReselected(Int)
    case home(AppHomeCoordinator.Action)
    case explore(AppHifiCoordinator.Action)
    case quickBattle(AppBattleCoordinator.Action)
    case myPage(AppProfileCoordinator.Action)
    case delegate(DelegateAction)
  }

  public enum DelegateAction: Equatable {
    case sessionEnded
  }

  @Dependency(\.analyticsUseCase) private var analyticsUseCase

  public var body: some ReducerOf<Self> {
    Scope(state: \.homeState, action: \.home) {
      AppHomeCoordinator()
    }
    Scope(state: \.exploreState, action: \.explore) {
      AppHifiCoordinator()
    }
    Scope(state: \.quickBattleState, action: \.quickBattle) {
      AppBattleCoordinator()
    }
    Scope(state: \.myPageState, action: \.myPage) {
      AppProfileCoordinator()
    }

    Reduce { state, action in
      switch action {
      case let .selectTab(tab):
        if tab != state.selectedTab {
          state.previousTab = state.selectedTab
          trackTabSelection(tab)
        }
        state.selectedTab = tab
        return .none

      case let .tabReselected(tab):
        resetSelectedTabRoute(state: &state, tab: tab)
        return .none

      case .quickBattle(.router(.routeAction(_, action: .battle(.delegate(.backToHome))))):
        state.selectedTab = state.previousTab
        return .none

      case .myPage(.router(.routeAction(_, action: .profile(.delegate(.backToHome))))):
        state.selectedTab = state.previousTab
        return .none

      case .myPage(.router(.routeAction(_, action: .settings(.delegate(.sessionEnded))))):
        return .send(.delegate(.sessionEnded))

      case .myPage(.router(.routeAction(_, action: .withdraw(.delegate(.sessionEnded))))):
        return .send(.delegate(.sessionEnded))

      case .home(.router(.routeAction(_, action: .home(.delegate(.moveToExplore))))):
        if state.selectedTab != Tab.explore.rawValue {
          state.previousTab = state.selectedTab
        }
        state.selectedTab = Tab.explore.rawValue
        return .none

      case .delegate:
        return .none

      case .home, .explore, .quickBattle, .myPage:
        return .none
      }
    }
  }
}

private extension AppMainTabCoordinator {
  func trackTabSelection(_ tab: Int) {
    switch Tab(rawValue: tab) {
    case .home:
      analyticsUseCase.track(.uiAction(action: .tabHome, screen: .mainTab))
    case .explore:
      analyticsUseCase.track(.uiAction(action: .tabExplore, screen: .mainTab))
    case .quickBattle:
      analyticsUseCase.track(.uiAction(action: .tabQuickBattle, screen: .mainTab))
    case .myPage:
      analyticsUseCase.track(.uiAction(action: .tabMypage, screen: .mainTab))
    case .none:
      break
    }
  }

  func resetSelectedTabRoute(
    state: inout State,
    tab: Int
  ) {
    switch Tab(rawValue: tab) {
    case .home:
      state.homeState.routes.goBackToRoot()
    case .explore:
      state.exploreState.routes.goBackToRoot()
    case .quickBattle:
      state.quickBattleState.routes.goBackToRoot()
    case .myPage:
      state.myPageState.routes.goBackToRoot()
    case .none:
      break
    }
  }
}
