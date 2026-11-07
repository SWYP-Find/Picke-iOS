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
  func failedHomeResponseShowsEmptyStateAndRetriesOnReentry() async {
    var state = HomeFeature.State()
    state.viewState = .loading
    state.hasTriedAttendance = true
    let store = TestStore(initialState: state) {
      HomeFeature()
    } withDependencies: {
      $0.analyticsUseCase.track = { _ in }
    }
    store.exhaustivity = .off

    await store.send(.inner(.homeResponse(.failure(.networkError("offline"))))) {
      $0.viewState = .failed
    }

    #expect(store.state.hasLoadedHome == false)
    #expect(store.state.shouldShowSkeleton == false)
    #expect(store.state.hasVisibleHomeContent == false)

    // 재진입 시 fetchHome 이 다시 시작돼 Mock 응답으로 로드가 끝난다(받는 순서가 보장되지 않아 최종 상태만 확인).
    await store.send(.view(.onAppear))
    await store.finish()
    await store.skipReceivedActions()
    #expect(store.state.hasLoadedHome)
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
      battleId: 21,
      battleTitle: "인간은 본래 선한가",
      optionTitle: "선하다",
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

  @Test
  @MainActor
  func homeTabReselectedScrollsToTopAndRefetches() async {
    var state = HomeFeature.State()
    state.viewState = .loaded
    state.hasLoadedHome = true
    let store = TestStore(initialState: state) {
      HomeFeature()
    }
    store.exhaustivity = .off

    await store.send(.view(.homeTabReselected))
    await store.receive(\.async) {
      $0.viewState = .loading
    }

    #expect(store.state.scrollToTopRequest == 1)
    await store.skipReceivedActions()
  }

  @Test
  @MainActor
  func homeTabReselectedWhileLoadingOnlyScrollsToTop() async {
    var state = HomeFeature.State()
    state.viewState = .loading
    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    await store.send(.view(.homeTabReselected)) {
      $0.scrollToTopRequest = 1
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
      battleId: 21,
      battleTitle: "인간은 본래 선한가",
      optionTitle: "선하다",
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
