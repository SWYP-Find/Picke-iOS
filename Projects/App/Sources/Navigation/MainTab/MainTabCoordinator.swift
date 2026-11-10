//
//  MainTabCoordinator.swift
//  Picke
//
//  Created by Picke on 7/11/26.
//

import AudioPlayerServiceInterface
import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
import PickeAnalyticsInterface
import PickeCoreUtility
import PickeDesignKit
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
    public var isKeyboardVisible = false
    public var homeState: HomeCoordinator.State
    public var exploreState: HifiCoordinator.State
    public var quickBattleState: BattleCoordinator.State
    public var classState: ClassCoordinator.State
    public var myPageState: ProfileCoordinator.State

    public var shouldHideTabBar: Bool {
      guard !isKeyboardVisible else { return true }
      switch Tab(rawValue: selectedTab) {
      case .home:
        return homeState.routes.count > 1 || homeState.routes.contains { route in
          guard case let .home(home) = route.screen else { return false }
          return home.attendanceModal != nil
        }
      case .explore:
        return exploreState.routes.count > 1
      case .quickBattle:
        return true
      case .classroom:
        return !classState.showsTabBar
      case .myPage:
        if case let .ticket(ticket)? = myPageState.routes.last?.screen { return ticket.customAlert != nil }
        return myPageState.routes.count > 1
      case .none:
        return false
      }
    }

    public func isSelected(_ tab: Tab) -> Bool {
      return selectedTab == tab.rawValue
    }

    public var backDestinationTab: Int {
      return previousTab == selectedTab ? Tab.home.rawValue : previousTab
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
    case tabTapped(Int)
    case selectTab(Int)
    case tabReselected(Int)
    case keyboardVisibilityChanged(Bool)
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
  @Dependency(\.battleUseCase) private var previewBattleUseCase
  @Dependency(\.audioPlayer) private var previewAudioPlayer

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
        .dependency(\.classBattlePreviewDependencies, .init(
          battleUseCase: previewBattleUseCase,
          audioPlayer: previewAudioPlayer,
          analyticsUseCase: analyticsUseCase
        ))
    }
    Scope(state: \.myPageState, action: \.myPage) {
      ProfileCoordinator()
    }

    Reduce { state, action in
      switch action {
      case let .tabTapped(tab):
        guard Tab(rawValue: tab) != nil else { return .none }
        return .send(tab == state.selectedTab ? .tabReselected(tab) : .selectTab(tab))

      case let .keyboardVisibilityChanged(isVisible):
        state.isKeyboardVisible = isVisible
        return .none

      case let .selectTab(tab):
        if tab != state.selectedTab {
          state.previousTab = state.selectedTab
          trackTabSelection(tab)
        }
        state.selectedTab = tab
        return .none

      case let .tabReselected(tab):
        return resetSelectedTabRoute(state: &state, tab: tab)

      case .quickBattle(.router(.routeAction(_, action: .battle(.delegate(.backToHome))))):
        state.selectedTab = state.backDestinationTab
        return .none

      case .myPage(.router(.routeAction(_, action: .profile(.delegate(.backToHome))))):
        state.selectedTab = state.backDestinationTab
        return .none

      case .classroom(.router(.routeAction(_, action: .intro(.delegate(.backToHome))))):
        state.selectedTab = state.backDestinationTab
        return .none

      case .classroom(.router(.routeAction(0, action: .intro(.delegate(.ticket))))):
        state.classState.routes.goBackToRoot()
        state.myPageState.routes.goBackToRoot()
        state.myPageState.routes.push(.ticket(.init()))
        if state.selectedTab != Tab.myPage.rawValue {
          state.previousTab = state.selectedTab
          trackTabSelection(Tab.myPage.rawValue)
        }
        state.selectedTab = Tab.myPage.rawValue
        return .none

      case .classroom(.router(.routeAction(0, action: .intro(.delegate(.registerTicket))))):
        // 만료 안내의 등록하기: Android와 같이 마이 탭의 코드 입력 화면으로 바로 간다.
        state.classState.routes.goBackToRoot()
        state.myPageState.routes.goBackToRoot()
        var registration = ClassTicketFeature.State()
        registration.shouldCheckExistingTicket = false
        state.myPageState.routes.push(.ticket(registration))
        if state.selectedTab != Tab.myPage.rawValue {
          state.previousTab = state.selectedTab
          trackTabSelection(Tab.myPage.rawValue)
        }
        state.selectedTab = Tab.myPage.rawValue
        return .none

      // Android `navigateToTab(Explore)` — 투표 포인트 부족 안내에서 배틀 흐름을 닫고 탐색 탭으로 간다.
      case .home(.router(.routeAction(_, action: .chat(.delegate(.openExplore))))):
        state.homeState.routes.goBackToRoot()
        return .send(.selectTab(Tab.explore.rawValue))

      case .explore(.router(.routeAction(_, action: .chat(.delegate(.openExplore))))):
        state.exploreState.routes.goBackToRoot()
        return .none

      case .quickBattle(.router(.routeAction(_, action: .chat(.delegate(.openExplore))))):
        state.quickBattleState.routes.goBackToRoot()
        return .send(.selectTab(Tab.explore.rawValue))

      case .classroom(.router(.routeAction(_, action: .chat(.delegate(.openExplore))))):
        state.classState.routes.goBackToRoot()
        return .send(.selectTab(Tab.explore.rawValue))

      case .myPage(.router(.routeAction(_, action: .chat(.delegate(.openExplore))))):
        state.myPageState.routes.goBackToRoot()
        return .send(.selectTab(Tab.explore.rawValue))

      case .myPage(.router(.routeAction(_, action: .settings(.delegate(.sessionEnded))))):
        return .send(.delegate(.sessionEnded))

      case .myPage(.router(.routeAction(_, action: .withdraw(.delegate(.sessionEnded))))):
        return .send(.delegate(.sessionEnded))

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
  ) -> Effect<Action> {
    switch Tab(rawValue: tab) {
    case .home:
      guard state.homeState.routes.count == 1 else {
        state.homeState.routes.goBackToRoot()
        return .none
      }
      return .send(.home(.router(.routeAction(
        id: 0,
        action: .home(.view(.homeTabReselected))
      ))))
    case .explore:
      guard state.exploreState.routes.count == 1 else {
        state.exploreState.routes.goBackToRoot()
        return .none
      }
      return .send(.explore(.router(.routeAction(
        id: 0,
        action: .hifi(.view(.exploreTabReselected))
      ))))
    case .quickBattle:
      state.quickBattleState.routes.goBackToRoot()
    case .classroom:
      return .send(.classroom(.view(.backToRootAction)))
    case .myPage:
      state.myPageState.routes.goBackToRoot()
    case .none:
      break
    }
    return .none
  }
}
