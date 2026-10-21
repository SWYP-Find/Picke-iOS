//
//  MainTabCoordinatorTests.swift
//  PickeTests
//
//  Created by Picke on 10/17/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
@testable import Picke
import PickeAnalyticsInterface
import TCAFlow
import Testing

@MainActor
struct MainTabCoordinatorTests {
  @Test
  func 클래스_미리듣기는_상위_분석_의존성을_사용한다() async {
    let tracked = LockIsolated(false)
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    var preview = ClassBattlePreviewFeature.State(battle: .mocks[0])
    preview.scenario = BattleScenario(
      battleId: preview.battle.id,
      title: "미리 듣기",
      philosophers: [],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: [:],
      nodes: []
    )
    state.classState.routes.push(.battlePreview(preview))
    var activePreview = preview
    activePreview.isActive = true
    let store = TestStore(initialState: state) {
      MainTabCoordinator()
    } withDependencies: {
      $0.analyticsUseCase.track = { event in
        guard case .screenView(screen: .classBattlePreview, referrer: .classRecommend) = event else { return }
        tracked.setValue(true)
      }
    }

    await store.send(.classroom(.router(.routeAction(
      id: 1,
      action: .battlePreview(.view(.onAppear))
    )))) {
      $0.classState.routes[1].screen = .battlePreview(activePreview)
    }
    #expect(tracked.value)
    await store.finish()
  }

  @Test
  func 탭_변경은_한번만_기록하고_재선택과_잘못된_탭은_기록하지_않는다() async {
    let events = LockIsolated<[AnalyticsButton]>([])
    let store = TestStore(initialState: MainTabCoordinator.State()) {
      MainTabCoordinator()
    } withDependencies: {
      $0.analyticsUseCase.track = { event in
        guard case let .uiAction(action, .mainTab) = event else { return }
        events.withValue { $0.append(action) }
      }
    }

    await store.send(.tabTapped(MainTabCoordinator.Tab.explore.rawValue))
    await store.receive(\.selectTab, MainTabCoordinator.Tab.explore.rawValue) {
      $0.selectedTab = MainTabCoordinator.Tab.explore.rawValue
    }
    #expect(events.value == [.tabExplore])

    await store.send(.tabTapped(MainTabCoordinator.Tab.explore.rawValue))
    await store.receive(\.tabReselected, MainTabCoordinator.Tab.explore.rawValue)
    await store.send(.tabTapped(-1))
    await store.finish()
    #expect(events.value == [.tabExplore])
  }

  @Test
  func 배틀_복귀_후_클래스를_재선택해도_소개에서_홈으로_나갈_수_있다() async {
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.quickBattle.rawValue)
    state.previousTab = MainTabCoordinator.Tab.classroom.rawValue
    state.classState.routes.push(.detail(.init(room: ClassRoom.mocks[0])))
    let classRoutes = state.classState.routes
    let store = TestStore(initialState: state) { MainTabCoordinator() }

    await store.send(.quickBattle(.router(.routeAction(
      id: 0,
      action: .battle(.view(.backTapped))
    ))))
    await store.receive {
      guard case .quickBattle(.router(.routeAction(_, action: .battle(.delegate(.backToHome))))) = $0 else {
        return false
      }
      return true
    } assert: {
      $0.selectedTab = MainTabCoordinator.Tab.classroom.rawValue
    }
    #expect(store.state.classState.routes == classRoutes)
    #expect(!store.state.shouldHideTabBar)

    await store.send(.tabTapped(MainTabCoordinator.Tab.classroom.rawValue))
    await store.receive(\.tabReselected, MainTabCoordinator.Tab.classroom.rawValue)
    await store.receive(\.classroom.view.backToRootAction) {
      $0.classState.routes.goBackToRoot()
    }
    #expect(store.state.shouldHideTabBar)
    await store.send(.classroom(.router(.routeAction(
      id: 0,
      action: .intro(.view(.backTapped))
    ))))
    await store.receive {
      guard case .classroom(.router(.routeAction(_, action: .intro(.delegate(.backToHome))))) = $0 else {
        return false
      }
      return true
    } assert: {
      $0.selectedTab = MainTabCoordinator.Tab.home.rawValue
    }
    #expect(!store.state.shouldHideTabBar)
    await store.finish()
  }

  @Test
  func 다른_탭_선택은_이전_탭과_다른_스택을_보존한다() async {
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    state.classState.routes.push(.detail(.init(room: ClassRoom.mocks[0])))
    let originalRoutes = state.classState.routes
    let store = TestStore(initialState: state) { MainTabCoordinator() }

    await store.send(.tabTapped(MainTabCoordinator.Tab.explore.rawValue))
    await store.receive(\.selectTab, MainTabCoordinator.Tab.explore.rawValue) {
      $0.previousTab = MainTabCoordinator.Tab.classroom.rawValue
      $0.selectedTab = MainTabCoordinator.Tab.explore.rawValue
    }
    #expect(store.state.classState.routes == originalRoutes)
    await store.send(.tabTapped(MainTabCoordinator.Tab.classroom.rawValue))
    await store.receive(\.selectTab, MainTabCoordinator.Tab.classroom.rawValue) {
      $0.previousTab = MainTabCoordinator.Tab.explore.rawValue
      $0.selectedTab = MainTabCoordinator.Tab.classroom.rawValue
    }
    #expect(store.state.classState.routes == originalRoutes)
    await store.finish()
  }

  @Test
  func 클래스_재선택은_클래스_루트만_초기화하고_인트로에서_탭바를_숨긴다() async {
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    state.classState.routes.push(.detail(.init(room: ClassRoom.mocks[0])))
    let homeRoutes = state.homeState.routes
    let store = TestStore(initialState: state) { MainTabCoordinator() }

    await store.send(.tabTapped(MainTabCoordinator.Tab.classroom.rawValue))
    await store.receive(\.tabReselected, MainTabCoordinator.Tab.classroom.rawValue)
    await store.receive(\.classroom.view.backToRootAction) {
      $0.classState.routes.goBackToRoot()
    }
    #expect(store.state.classState.routes.count == 1)
    #expect(store.state.homeState.routes == homeRoutes)
    #expect(store.state.shouldHideTabBar)
    await store.finish()
  }

  @Test
  func 키보드와_화면_상태에_따라_탭바가_복원된다() async {
    var state = MainTabCoordinator.State()
    #expect(!state.shouldHideTabBar)
    state.isKeyboardVisible = true
    #expect(state.shouldHideTabBar)
    let store = TestStore(initialState: state) { MainTabCoordinator() }
    await store.send(.keyboardVisibilityChanged(false)) {
      $0.isKeyboardVisible = false
    }
    await store.finish()
    #expect(!store.state.shouldHideTabBar)

    var quickBattle = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.quickBattle.rawValue)
    #expect(quickBattle.shouldHideTabBar)
    quickBattle.selectedTab = MainTabCoordinator.Tab.classroom.rawValue
    #expect(quickBattle.shouldHideTabBar)
    var list = MyClassFeature.State()
    list.rooms = ClassRoom.mocks
    list.viewState = .loaded
    quickBattle.classState.routes.push(.myClasses(list))
    #expect(!quickBattle.shouldHideTabBar)
    quickBattle.isKeyboardVisible = true
    #expect(quickBattle.shouldHideTabBar)
    quickBattle.isKeyboardVisible = false
    #expect(!quickBattle.shouldHideTabBar)
  }

  @Test
  func 홈_출석_모달과_깊은_경로는_탭바를_숨기고_복원한다() async {
    var state = MainTabCoordinator.State()
    guard case var .home(home) = state.homeState.routes[0].screen else {
      Issue.record("Home root is missing")
      return
    }
    home.attendanceModal = .init()
    state.homeState.routes[screenAt: 0] = .home(home)
    #expect(state.shouldHideTabBar)
    home.attendanceModal = nil
    state.homeState.routes[screenAt: 0] = .home(home)
    #expect(!state.shouldHideTabBar)

    state.homeState.routes.push(.notification(.init(route: .inbox)))
    let deepRoutes = state.homeState.routes
    #expect(state.shouldHideTabBar)
    let store = TestStore(initialState: state) { MainTabCoordinator() }
    await store.send(.tabTapped(MainTabCoordinator.Tab.explore.rawValue))
    await store.receive(\.selectTab, MainTabCoordinator.Tab.explore.rawValue) {
      $0.previousTab = MainTabCoordinator.Tab.home.rawValue
      $0.selectedTab = MainTabCoordinator.Tab.explore.rawValue
    }
    #expect(!store.state.shouldHideTabBar)
    await store.send(.tabTapped(MainTabCoordinator.Tab.home.rawValue))
    await store.receive(\.selectTab, MainTabCoordinator.Tab.home.rawValue) {
      $0.previousTab = MainTabCoordinator.Tab.explore.rawValue
      $0.selectedTab = MainTabCoordinator.Tab.home.rawValue
    }
    #expect(store.state.homeState.routes == deepRoutes)
    #expect(store.state.shouldHideTabBar)
    await store.finish()
  }
}
