//
//  HomeTests.swift
//  HomeTests
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import Foundation
import HomeDomainInterface
import Testing

@testable import Home

struct HomeTests {
  @Test
  func initialEmptyHomeShowsSkeletonBeforeOnAppear() {
    let state = HomeFeature.State()

    #expect(state.shouldShowSkeleton)
  }

  @Test
  @MainActor
  func failedHomeResponseAllowsRetryOnReentry() async {
    var state = HomeFeature.State()
    state.viewState = .loading
    let store = TestStore(initialState: state) {
      HomeFeature()
    }

    await store.send(.inner(.homeResponse(.failure(.networkError("offline"))))) {
      $0.viewState = .loaded
    }

    #expect(store.state.hasLoadedHome == false)
    #expect(store.state.shouldShowSkeleton)
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
