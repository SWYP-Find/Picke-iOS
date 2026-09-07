//
//  SecureStorageKey.swift
//  PickeStorageInterface
//

public struct SecureStorageKey: Hashable, Sendable {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
}

public extension SecureStorageKey {
  // 이전 버전이 쓰던 Keychain 계정명을 그대로 유지해 업데이트 후에도 세션이 살아있게 한다.
  static let accessToken = SecureStorageKey("ACCESS_TOKEN")
  static let refreshToken = SecureStorageKey("REFRESH_TOKEN")

  static let all: [SecureStorageKey] = [.accessToken, .refreshToken]
}
