import Foundation

import Dependencies
import Sharing

public extension SharedReaderKey where Self == PersistentSharedKey<String?>.Default {
  /// APNs 디바이스 토큰. 기존 UserDefaults key 를 첫 조회 때 이관한다.
  static var deviceToken: Self {
    Self[
      .persistent(
        PushStorageKey.deviceToken.rawValue,
        encode: { try JSONEncoder().encode($0) },
        decode: { try JSONDecoder().decode(String?.self, from: $0) },
        legacyData: {
          @Dependency(\.keyValueStorage) var keyValueStorage
          guard let token: String = keyValueStorage.load(PushStorageKey.deviceToken) else { return nil }
          return try JSONEncoder().encode(token)
        }
      ),
      default: nil
    ]
  }
}
