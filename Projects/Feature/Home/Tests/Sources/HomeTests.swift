//
//  HomeTests.swift
//  HomeTests
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import Foundation
@testable import Home
import HomeDomainInterface
import PickeAnalyticsInterface
import Testing

struct HomeTests {
  @Test
  func initialEmptyHomeShowsSkeletonBeforeOnAppear() {
    let state = HomeFeature.State()

    #expect(state.shouldShowSkeleton)
  }

  @Test
  @MainActor
  func failedHomeResponseShowsEmptyStateAndToastWithoutRefetchOnReentry() async {
    var state = HomeFeature.State()
    state.viewState = .loading
    state.hasTriedAttendance = true
    let fetchCount = LockIsolated(0)
    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.analyticsUseCase.track = { _ in }
      $0.homeUseCase = StubHomeUseCase {
        fetchCount.withValue { $0 += 1 }
        return .badgeStaleMock
      }
    }

    await store.send(.inner(.homeResponse(.failure(.networkError("offline"))))) {
      $0.viewState = .failed
      $0.toastMessage = "정보를 불러오지 못했어요"
    }

    #expect(store.state.hasLoadedHome == false)
    #expect(store.state.shouldShowSkeleton == false)
    #expect(store.state.hasVisibleHomeContent == false)

    // Android 처럼 재진입해도 다시 부르지 않는다(새로고침으로만 다시 부름).
    store.exhaustivity = .off
    await store.send(.view(.onAppear))
    await store.finish()
    await store.skipReceivedActions()
    #expect(fetchCount.value == 0)
    #expect(store.state.viewState == .failed)
  }

  @Test
  @MainActor
  func firstOnAppearFetchesHomeOnce() async {
    var state = HomeFeature.State()
    state.hasTriedAttendance = true
    let fetchCount = LockIsolated(0)
    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.analyticsUseCase.track = { _ in }
      $0.homeUseCase = StubHomeUseCase {
        fetchCount.withValue { $0 += 1 }
        return .badgeStaleMock
      }
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchHome) {
      $0.viewState = .loading
    }
    await store.receive(\.inner.homeResponse) {
      $0.viewState = .loaded
      $0.hasLoadedHome = true
    }
    await store.finish()

    // 로드가 끝난 뒤 재진입해도 다시 부르지 않는다.
    await store.send(.view(.onAppear))
    await store.finish()
    await store.skipReceivedActions()
    #expect(fetchCount.value == 1)
  }

  @Test
  @MainActor
  func unreadBadgeSuccessStopsBellLoadingAndShowsBadge() async {
    var state = HomeFeature.State()
    state.hasLoadedHome = true
    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    await store.send(.inner(.unreadBadgeResponse(.success(true)))) {
      $0.isUnreadBadgeLoading = false
      $0.hasUnreadNotification = true
    }
    #expect(store.state.shouldShowBellSkeleton == false)
  }

  @Test
  @MainActor
  func pullToRefreshReloadsWithoutSkeleton() async {
    let comment = HomeBestComment(
      perspectiveId: 501,
      battleId: 21,
      battleTitle: "인간은 본래 선한가",
      content: "선하게 태어나요"
    )
    var state = HomeFeature.State()
    state.viewState = .loaded
    state.hasLoadedHome = true
    state.bestComments = [comment]
    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.homeUseCase = StubHomeUseCase { .badgeStaleMock }
    }

    await store.send(.view(.pullToRefresh))
    await store.receive(\.async.refreshHome)
    #expect(store.state.shouldShowSkeleton == false)
    await store.receive(\.inner.homeResponse) {
      $0.newNotice = true
      $0.bestComments = []
    }
  }

  @Test
  @MainActor
  func pullToRefreshFailureKeepsContentAndShowsToast() async {
    let comment = HomeBestComment(
      perspectiveId: 501,
      battleId: 21,
      battleTitle: "인간은 본래 선한가",
      content: "선하게 태어나요"
    )
    var state = HomeFeature.State()
    state.viewState = .loaded
    state.hasLoadedHome = true
    state.bestComments = [comment]
    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.homeUseCase = StubHomeUseCase { throw URLError(.notConnectedToInternet) }
    }

    await store.send(.view(.pullToRefresh))
    await store.receive(\.async.refreshHome)
    await store.receive(\.inner.homeResponse) {
      $0.viewState = .failed
      $0.toastMessage = "정보를 불러오지 못했어요"
    }
    #expect(store.state.bestComments == [comment])

    await store.send(.view(.toastShown)) {
      $0.toastMessage = nil
    }
  }

  @Test
  @MainActor
  func pullToRefreshIsIgnoredWhileFirstLoading() async {
    var state = HomeFeature.State()
    state.viewState = .loading
    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    await store.send(.view(.pullToRefresh))
  }

  @Test
  @MainActor
  func unreadBadgeFailureStopsBellLoadingAndKeepsBadge() async {
    var state = HomeFeature.State()
    state.hasUnreadNotification = true
    state.hasLoadedHome = true
    let store = TestStore(initialState: state) {
      HomeFeature()
    }
    #expect(store.state.shouldShowBellSkeleton)

    await store.send(.inner(.unreadBadgeResponse(.failure(.networkError("offline"))))) {
      $0.isUnreadBadgeLoading = false
    }
    #expect(store.state.hasUnreadNotification)
    #expect(store.state.shouldShowBellSkeleton == false)
  }

  @Test
  func visibleBestBattlesShowsOnlyFirstThree() {
    var state = HomeFeature.State()
    state.bestBattles = (1 ... 4).map {
      BestBattle(
        battleId: $0,
        rank: $0,
        philosopherA: "A",
        philosopherB: "B",
        title: "배틀 \($0)",
        audioDuration: 60,
        viewCount: 10
      )
    }

    #expect(state.visibleBestBattles.map(\.battleId) == [1, 2, 3])
  }

  @Test
  @MainActor
  func bestCommentTapTracksBestCommentSectionAndPresentsPreVote() async {
    let comment = HomeBestComment(
      perspectiveId: 501,
      battleId: 21,
      battleTitle: "인간은 본래 선한가",
      content: "선하게 태어나요"
    )
    let tracked = LockIsolated<[ContentActionData]>([])
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.analyticsUseCase.track = { event in
        guard case let .contentAction(data) = event else { return }
        tracked.withValue { $0.append(data) }
      }
    }

    await store.send(.view(.bestCommentTapped(comment)))
    await store.receive(\.delegate)

    #expect(tracked.value.count == 1)
    #expect(tracked.value.first?.section == .bestComment)
    #expect(tracked.value.first?.contentID == "21")
  }

  /// Android 처럼 홈 탭 재선택은 어떤 상태에서든 맨 위로만 올리고 다시 부르지 않는다.
  @Test
  @MainActor
  func homeTabReselectedOnlyScrollsToTop() async {
    let viewStates: [HomeFeature.State.ViewState] = [.loaded, .loading, .failed]
    for viewState in viewStates {
      var state = HomeFeature.State()
      state.viewState = viewState
      state.hasLoadedHome = viewState == .loaded
      let store = TestStore(initialState: state) {
        HomeFeature()
      }

      await store.send(.view(.homeTabReselected)) {
        $0.scrollToTopRequest = 1
      }
    }
  }

  @Test
  @MainActor
  func homeResponseDoesNotTouchNotificationBadge() async {
    // 벨 배지는 서버(/unread)로만 갱신 — homeResponse(newNotice 포함)는 배지를 건드리지 않는다.
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    }

    await store.send(.inner(.homeResponse(.success(.badgeStaleMock)))) {
      $0.hasLoadedHome = true
      $0.newNotice = true
    }

    #expect(store.state.hasUnreadNotification == false)
    #expect(store.state.shouldShowSkeleton == false)
  }

  @Test
  @MainActor
  func homeResponseStoresBestCommentsWithoutMockFallback() async {
    let comment = HomeBestComment(
      perspectiveId: 501,
      battleId: 21,
      battleTitle: "인간은 본래 선한가",
      content: "선하게 태어나요"
    )
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    }

    await store.send(.inner(.homeResponse(.success(.commentsOnly(comment))))) {
      $0.hasLoadedHome = true
      $0.bestComments = [comment]
    }

    #expect(store.state.hotBattles.isEmpty)
    #expect(store.state.hasVisibleHomeContent)
    #expect(store.state.shouldShowSkeleton == false)
  }

  @Test
  func loadedEmptyHomeHasNoVisibleContent() {
    var state = HomeFeature.State()
    state.hasLoadedHome = true

    #expect(state.shouldShowSkeleton == false)
    #expect(state.hasVisibleHomeContent == false)
  }
}

/// 홈 조회 결과를 테스트마다 정하는 가짜 UseCase.
private struct StubHomeUseCase: HomeInterface {
  let fetch: @Sendable () async throws -> HomeBundle

  init(_ fetch: @escaping @Sendable () async throws -> HomeBundle) {
    self.fetch = fetch
  }

  func fetchHome() async throws -> HomeBundle {
    try await fetch()
  }
}

private extension HomeBundle {
  static let badgeStaleMock = HomeBundle(
    newNotice: true,
    heroes: [],
    hotBattles: [],
    bestBattles: [],
    quizzes: [],
    votes: [],
    newBattles: []
  )

  static func commentsOnly(_ comment: HomeBestComment) -> HomeBundle {
    HomeBundle(
      newNotice: false,
      heroes: [],
      hotBattles: [],
      bestBattles: [],
      bestComments: [comment],
      quizzes: [],
      votes: [],
      newBattles: []
    )
  }
}
