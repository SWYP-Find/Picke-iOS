//
//  SecureStorage.swift
//  PickeStorageInterface
//

/// 민감한 문자열을 보관하는 저장소 경계.
public protocol SecureStorage: Sendable {
  func save(_ value: String, for key: SecureStorageKey) throws(SecureStorageError)
  func load(_ key: SecureStorageKey) throws(SecureStorageError) -> String?
  func remove(_ key: SecureStorageKey) throws(SecureStorageError)
  func removeAll() throws(SecureStorageError)
}
