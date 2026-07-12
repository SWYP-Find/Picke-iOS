import ComposableArchitecture
import Entity
import Foundation
import HomeDomainInterface
import Testing

@testable import Home

struct HomeTests {
  @Test
  @MainActor
  func homeResponseDoesNotReviveNotificationBadgeFromNewNotice() async {
    UserDefaults.standard.set(false, forKey: "HasUnreadNotification")
    UserDefaults.standard.set(false, forKey: "NotificationReadAllPending")

    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    }

    await store.send(.inner(.homeResponse(.success(.badgeStaleMock)))) {
      $0.hasLoadedHome = true
      $0.newNotice = true
    }
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
