import ComposableArchitecture
import PickeAnalyticsInterface
import PickeCoreUtility
import PickeStorageInterface
import Testing

@testable import Picke

@MainActor
struct AppDeeplinkRoutingTests {
  @Test
  func 로그인_전에는_보류하고_메인_진입시_한번만_소비한다() async {
    await withDependencies {
      $0.context = .test
      $0.defaultInMemoryStorage = InMemoryStorage()
      $0.analyticsUseCase = AnalyticsUseCase(
        registerBaseProperties: {},
        identify: { _, _ in },
        track: { _ in },
        reset: {}
      )
    } operation: {
      @Shared(.pendingDeeplink) var pending: String?
      $pending.withLock { $0 = PickeDeeplink.quickBattle.encoded }
      let store = TestStore(initialState: AppReducer.State()) {
        AppReducer()
      }
      store.exhaustivity = .off

      await store.send(.async(.consumePendingDeeplink))
      #expect(pending == PickeDeeplink.quickBattle.encoded)

      await store.send(.inner(.completeMainTabTransition))
      await store.receive(\.async.consumePendingDeeplink)
      await store.receive(\.scope.mainTab.selectTab)
      guard case let .mainTab(state) = store.state else {
        Issue.record("메인 화면으로 전환되지 않음")
        return
      }
      #expect(state.selectedTab == AppMainTabCoordinator.Tab.quickBattle.rawValue)
      #expect(pending == nil)
      await store.send(.async(.consumePendingDeeplink))
      await store.finish()
    }
  }
}
