import Foundation

import Dependencies
import Sharing

public extension SharedReaderKey where Self == PersistentSharedKey<String?>.Default {
  /// 메인 화면 진입 전 도착한 최신 딥링크. 소비한 nil도 저장해 이전 값을 다시 읽지 않는다.
  static var pendingDeeplink: Self {
    @Dependency(\.keyValueStorage) var storage
    return Self[
      .persistent(
        PushStorageKey.pendingDeeplink.rawValue,
        encode: { try JSONEncoder().encode($0) },
        decode: { try JSONDecoder().decode(String?.self, from: $0) },
        legacyData: {
          guard let value = storage.load(PushStorageKey.pendingDeeplink) else { return nil }
          return try JSONEncoder().encode(value)
        }
      ),
      default: nil
    ]
  }
}
