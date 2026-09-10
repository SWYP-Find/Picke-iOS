import PickeCoreUtility
import PickeStorageInterface

import Sharing

/// 기존 Storage의 영속·테스트 메모리 경계를 사용해 최신 요청 하나만 보관한다.
struct PendingDeeplinkStore: Sendable {
  @Shared(.pendingDeeplink) private var encoded: String?

  func save(_ deeplink: PickeDeeplink) {
    $encoded.withLock { $0 = deeplink.encoded }
  }

  func consume() -> PickeDeeplink? {
    $encoded.withLock { value in
      defer { value = nil }
      return value.flatMap { PickeDeeplinkParser.parse(urlString: $0) }
    }
  }
}
