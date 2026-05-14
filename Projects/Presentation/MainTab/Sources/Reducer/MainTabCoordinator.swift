//
//  MainTabCoordinator.swift
//  MainTab
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

import ComposableArchitecture
import TCAFlow

import DesignSystem
import Home

/// 픽케 메인 탭 코디네이터.
/// 모든 탭은 우선 HomeCoordinator 로 채워두고, 각 기능 (Explore / QuickBattle / MyPage)
/// 모듈이 추가될 때 해당 child state 만 교체한다.
@Reducer
public struct MainTabCoordinator {
  public init() {}

  public enum Tab: Int, CaseIterable {
    case home
    case explore
    case quickBattle
    case myPage

    public var title: String {
      switch self {
      case .home: "홈"
      case .explore: "탐색"
      case .quickBattle: "빠른 배틀"
      case .myPage: "마이"
      }
    }

    /// 디자인 시스템 GNB 아이콘 (Pencil 추출 PNG)
    public var iconAsset: ImageAsset {
      switch self {
      case .home: .tabHome
      case .explore: .tabExplore
      case .quickBattle: .tabQuickBattle
      case .myPage: .tabMyPage
      }
    }
  }

  @ObservableState
  public struct State: Equatable {
    public var selectedTab: Int
    public var homeState: HomeCoordinator.State
    public var exploreState: HomeCoordinator.State
    public var quickBattleState: HomeCoordinator.State
    public var myPageState: HomeCoordinator.State

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
    case home(HomeCoordinator.Action)
    case explore(HomeCoordinator.Action)
    case quickBattle(HomeCoordinator.Action)
    case myPage(HomeCoordinator.Action)
  }

  public var body: some ReducerOf<Self> {
    Scope(state: \.homeState, action: \.home) {
      HomeCoordinator()
    }
    Scope(state: \.exploreState, action: \.explore) {
      HomeCoordinator()
    }
    Scope(state: \.quickBattleState, action: \.quickBattle) {
      HomeCoordinator()
    }
    Scope(state: \.myPageState, action: \.myPage) {
      HomeCoordinator()
    }

    Reduce { state, action in
      switch action {
      case let .selectTab(tab):
        state.selectedTab = tab
        return .none

      case let .tabReselected(tab):
        // 같은 탭 재탭 → 해당 탭의 navigation stack 을 root 로 되돌림
        switch Tab(rawValue: tab) {
        case .home: state.homeState.routes.goBackToRoot()
        case .explore: state.exploreState.routes.goBackToRoot()
        case .quickBattle: state.quickBattleState.routes.goBackToRoot()
        case .myPage: state.myPageState.routes.goBackToRoot()
        case .none: break
        }
        return .none

      case .home, .explore, .quickBattle, .myPage:
        return .none
      }
    }
  }
}
