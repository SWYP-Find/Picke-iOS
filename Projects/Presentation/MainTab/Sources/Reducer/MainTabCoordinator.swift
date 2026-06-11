//
//  MainTabCoordinator.swift
//  MainTab
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

import ComposableArchitecture
import TCAFlow

import Battle
import DesignSystem
import Hifi
import Home
import Profile

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

    /// 디자인 시스템 GNB 아이콘 (탭바 아이콘 폴더 PNG, single-scale)
    public func iconAsset(isSelected: Bool) -> ImageAsset {
      switch self {
      case .home: isSelected ? .tabHomeActive : .tabHome
      case .explore: isSelected ? .tabExploreActive : .tabExplore
      case .quickBattle: isSelected ? .tabQuickBattleActive : .tabQuickBattle
      case .myPage: isSelected ? .tabMyPageActive : .tabMyPage
      }
    }
  }

  @ObservableState
  public struct State: Equatable {
    public var selectedTab: Int
    /// 직전 탭 — 탐색/빠른배틀 상단 백탭 시 이 탭으로 복귀.
    public var previousTab: Int = Tab.home.rawValue
    public var homeState: HomeCoordinator.State
    public var exploreState: HifiCoordinator.State
    public var quickBattleState: BattleCoordinator.State
    public var myPageState: ProfileCoordinator.State

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
    case explore(HifiCoordinator.Action)
    case quickBattle(BattleCoordinator.Action)
    case myPage(ProfileCoordinator.Action)
    case delegate(DelegateAction)
  }

  public enum DelegateAction: Equatable {
    /// 로그아웃/탈퇴 완료 → 루트(App)에서 로그인 화면으로 전환.
    case sessionEnded
  }

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
    Scope(state: \.myPageState, action: \.myPage) {
      ProfileCoordinator()
    }

    Reduce { state, action in
      switch action {
      case let .selectTab(tab):
        if tab != state.selectedTab { state.previousTab = state.selectedTab }
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

      // 빠른배틀(오늘의 배틀) 상단 백탭 → 직전 탭으로 복귀
      case .quickBattle(.router(.routeAction(_, action: .battle(.delegate(.backToHome))))):
        state.selectedTab = state.previousTab
        return .none

      // 마이 상단 백탭 → 직전 탭으로 복귀
      case .myPage(.router(.routeAction(_, action: .profile(.delegate(.backToHome))))):
        state.selectedTab = state.previousTab
        return .none

      // 설정 → 로그아웃 완료 → App 으로 세션 종료 전파
      case .myPage(.router(.routeAction(_, action: .settings(.delegate(.sessionEnded))))):
        return .send(.delegate(.sessionEnded))

      // 회원 탈퇴 완료 → App 으로 세션 종료 전파
      case .myPage(.router(.routeAction(_, action: .withdraw(.delegate(.sessionEnded))))):
        return .send(.delegate(.sessionEnded))

      // 홈 "더보기" → 탐색 탭으로 이동
      case .home(.router(.routeAction(_, action: .home(.delegate(.moveToExplore))))):
        if state.selectedTab != Tab.explore.rawValue { state.previousTab = state.selectedTab }
        state.selectedTab = Tab.explore.rawValue
        return .none

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)

      case .home, .explore, .quickBattle, .myPage:
        return .none
      }
    }
  }

  /// delegate 는 부모(App)가 관찰 — MainTab 은 발행만 하고 여기서는 가로채지 않는다.
  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .sessionEnded:
      return .none
    }
  }
}
