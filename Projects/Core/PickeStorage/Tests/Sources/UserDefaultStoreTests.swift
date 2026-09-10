import Foundation
import PickeStorageInterface
import Testing

@testable import PickeStorage

struct UserDefaultStoreTests {
  @Test
  func 푸시_키는_이전_문자열을_유지한다() {
    #expect(PushStorageKey.deviceToken.rawValue == "PickeDeviceToken")
    #expect(PushStorageKey.pendingDeeplink.rawValue == "PickePendingDeeplink")
  }

  @Test
  func 타입_키로_저장하고_nil로_제거한다() {
    let store = UserDefaultStore(suiteName: "PickeStorageTests.\(UUID().uuidString)")
    defer { store.save(nil, for: PushStorageKey.deviceToken) }
    #expect(store.load(PushStorageKey.deviceToken) == nil)
    store.save("token", for: PushStorageKey.deviceToken)
    #expect(store.load(PushStorageKey.deviceToken) == "token")
    store.save(nil, for: PushStorageKey.deviceToken)
    #expect(store.load(PushStorageKey.deviceToken) == nil)
  }

  @Test
  func 서로_다른_suite의_값을_공유하지_않는다() {
    let first = UserDefaultStore(suiteName: "PickeStorageTests.\(UUID().uuidString)")
    let second = UserDefaultStore(suiteName: "PickeStorageTests.\(UUID().uuidString)")
    defer { first.save(nil, for: PushStorageKey.pendingDeeplink) }
    first.save("quick-battle", for: PushStorageKey.pendingDeeplink)
    #expect(first.load(PushStorageKey.pendingDeeplink) == "quick-battle")
    #expect(second.load(PushStorageKey.pendingDeeplink) == nil)
  }
}
