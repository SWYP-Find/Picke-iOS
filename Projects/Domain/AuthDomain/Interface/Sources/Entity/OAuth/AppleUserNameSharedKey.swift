//
//  AppleUserNameSharedKey.swift
//  AuthDomainInterface
//

import Foundation

import PickeStorageInterface

import Sharing

public extension SharedReaderKey where Self == PersistentSharedKey<String?>.Default {
  /// Apple 로그인이 최초 1회만 내려주는 표시 이름.
  static var appleUserName: Self {
    Self[
      .persistent(
        "AppleUserName",
        encode: { name in
          try JSONEncoder().encode(AppleUserNameSnapshot(name))
        },
        decode: { data in
          try JSONDecoder().decode(AppleUserNameSnapshot.self, from: data).name
        },
        legacyData: {
          // `.appStorage("appleUserName")` 로 쌓아둔 값을 첫 조회 때 옮긴다.
          guard let name = UserDefaults.standard.string(forKey: "appleUserName") else { return nil }
          return try JSONEncoder().encode(AppleUserNameSnapshot(name))
        }
      ),
      default: nil
    ]
  }
}

private struct AppleUserNameSnapshot: Codable, Sendable {
  let schemaVersion: Int
  let name: String?

  init(_ name: String?) {
    schemaVersion = 1
    self.name = name
  }
}
