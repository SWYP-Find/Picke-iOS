import ComposableArchitecture
import PickeCoreUtility
import PickeStorageInterface
import Testing

@testable import Picke

struct PendingDeeplinkStoreTests {
  @Test
  func 대기_링크는_한번만_소비된다() {
    withDependencies {
      $0.context = .test
    } operation: {
      let store = PendingDeeplinkStore()
      store.save(.quickBattle)
      #expect(store.consume() == .quickBattle)
      #expect(store.consume() == nil)
    }
  }

  @Test
  func 저장소_사이에_최신_대기_링크를_공유한다() {
    withDependencies {
      $0.context = .test
    } operation: {
      let first = PendingDeeplinkStore()
      let second = PendingDeeplinkStore()
      first.save(.battle(battleId: 1))
      second.save(.quickBattle)
      #expect(first.consume() == .quickBattle)
      #expect(second.consume() == nil)
    }
  }

  @Test
  func 잘못된_링크도_소비하면_제거한다() {
    withDependencies {
      $0.context = .test
    } operation: {
      @Shared(.pendingDeeplink) var encoded: String?
      $encoded.withLock { $0 = "invalid" }
      #expect(PendingDeeplinkStore().consume() == nil)
      #expect(encoded == nil)
    }
  }
}
