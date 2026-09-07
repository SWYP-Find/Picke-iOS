//
//  AuthTestDoubles.swift
//  PickeAuthTests
//

import Foundation

import PickeStorageInterface

/// Keychain 대신 메모리 딕셔너리로 동작하는 보안 저장소 — 테스트 간 상태가 남지 않는다.
final class FakeSecureStorage: SecureStorage, @unchecked Sendable {
  var values: [SecureStorageKey: String]

  init(values: [SecureStorageKey: String] = [:]) {
    self.values = values
  }

  func save(_ value: String, for key: SecureStorageKey) throws(SecureStorageError) {
    values[key] = value
  }

  func load(_ key: SecureStorageKey) throws(SecureStorageError) -> String? {
    values[key]
  }

  func remove(_ key: SecureStorageKey) throws(SecureStorageError) {
    values[key] = nil
  }

  func removeAll() throws(SecureStorageError) {
    values.removeAll()
  }
}
