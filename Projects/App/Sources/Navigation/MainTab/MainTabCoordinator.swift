//
//  MainTabCoordinator.swift
//  Picke
//
//  Created by Codex on 7/11/26.
//

import Foundation

import PickeAnalyticsInterface
import ComposableArchitecture
import PickeDesignKit
import FeatureAssembly
import TCAFlow

@Reducer
public struct MainTabCoordinator {
  public init() {}

  public enum Tab: Int, CaseIterable {
    case home = 0
    case explore = 1
    case quickBattle = 2
    case classroom = 4
    case myPage = 3

    public var title: String {
      switch self {
      case .home: return "홈"
      case .explore: return "탐색"
      case .quickBattle: return "빠른 배틀"
      case .classroom: return "클래스"
      case .myPage: return "마이"
      }
    }

    public func iconAsset(isSelected: Bool) -> ImageAsset {
      switch self {
      case .home: return isSelected ? .tabHomeActive : .tabHome
      case .explore: return isSelected ? .tabExploreActive : .tabExplore
      case .quickBattle: return isSelected ? .tabQuickBattleActive : .tabQuickBattle
      case .classroom: return isSelected ? .tabClassActive : .tabClass
      case .myPage: return isSelected ? .tabMyPageActive : .tabMyPage
      }
    }
  }

  @ObservableState
  public struct State: Equatable {
    public var selectedTab: Int
    public var previousTab: Int = Tab.home.rawValue
    public var homeState: HomeCoordinator.State
    public var exploreState: HifiCoordinator.State
    public var quickBattleState: BattleCoordinator.State
    public var classState: ClassCoordinator.State
    public var myPageState: ProfileCoordinator.State

    public var shouldHideTabBar: Bool {
      switch Tab(rawValue: selectedTab) {
      case .home:
        return homeState.routes.count > 1
      case .explore:
        return exploreState.routes.count > 1
      case .quickBattle:
        return quickBattleState.routes.count > 1
      case .classroom:
        return !classState.showsTabBar
      case .myPage:
        return myPageState.routes.count > 1
      case .none:
        return false
      }
    }

    public init(selectedTab: Int = Tab.home.rawValue) {
      self.selectedTab = selectedTab
      homeState = .init()
      exploreState = .init()
      quickBattleState = .init()
      classState = .init()
      myPageState = .init()
    }
  }

  @CasePathable
  public enum Action {
    case selectTab(Int)
    case tabReselected(Int)
    case home(HomeCoordinator.Action)
    case explore(HifiCoordinator.Action)
    case quickBattle(BattleCoordinator.Action)
    case classroom(ClassCoordinator.Action)
    case myPage(ProfileCoordinator.Action)
    case delegate(DelegateAction)
  }

  public enum DelegateAction: Equatable {
    case sessionEnded
  }

  @Dependency(\.analyticsUseCase) private var analyticsUseCase

  public var body: some ReducerOf<Self> {
    Scope(state: \.homeState, action: \.home) {
      HomeCoordinator()
    }
    Scope(state: \.exploreState, action: \.explore) {
      HifiCoordinator()
    }
    Scope(state: \.quickBattleState, action: \.quickBattle) {
      BattleCoordinator()
    }
    Scope(state: \.classState, action: \.classroom) {
      ClassCoordinator()
    }
    Scope(state: \.myPageState, action: \.myPage) {
      ProfileCoordinator()
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

      case .classroom(.router(.routeAction(_, action: .intro(.delegate(.backToHome))))):
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

      case .home, .explore, .quickBattle, .classroom, .myPage:
        return .none
      }
    }
  }
}

private extension MainTabCoordinator {
  func trackTabSelection(_ tab: Int) {
    switch Tab(rawValue: tab) {
    case .home:
      analyticsUseCase.track(.uiAction(action: .tabHome, screen: .mainTab))
    case .explore:
      analyticsUseCase.track(.uiAction(action: .tabExplore, screen: .mainTab))
    case .quickBattle:
      analyticsUseCase.track(.uiAction(action: .tabQuickBattle, screen: .mainTab))
    case .classroom:
      analyticsUseCase.track(.uiAction(action: .tabClass, screen: .mainTab))
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
    case .classroom:
      state.classState.routes.goBackToRoot()
    case .myPage:
      state.myPageState.routes.goBackToRoot()
    case .none:
      break
    }
  }
}
