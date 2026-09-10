import ComposableArchitecture
import TCAFlow
import Testing

@testable import Picke

@MainActor
struct NotificationCoordinatorTests {
  @Test
  func route초기화는_알림_목록을_루트로_연다() {
    let state = NotificationCoordinator.State(route: .inbox)

    #expect(state.routes.count == 1)
    guard let route = state.routes.first else {
      Issue.record("알림 루트 route가 없음")
      return
    }
    #expect(route.embedInNavigationView)
    guard case .notification = route.screen else {
      Issue.record("알림 목록 화면으로 시작하지 않음")
      return
    }
  }

  @Test
  func 알림_목록_dismiss는_부모_delegate로_전달된다() async {
    let store = TestStore(initialState: NotificationCoordinator.State(route: .inbox)) {
      NotificationCoordinator()
    }

    await store.send(.router(.routeAction(
      id: 0,
      action: .notification(.delegate(.dismiss))
    )))
    await store.receive {
      guard case .delegate(.dismiss) = $0 else { return false }
      return true
    }
    await store.finish()
  }
}
