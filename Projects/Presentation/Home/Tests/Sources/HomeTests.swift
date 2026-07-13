import ComposableArchitecture
import Entity
import Foundation
import HomeDomainInterface
import Testing

@testable import Home

struct HomeTests {
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
}
