//
//  SecureStorage.swift
//  PickeStorageInterface
//

/// 민감한 문자열을 보관하는 저장소 경계.
///
/// 도메인은 Keychain(Security 프레임워크) 구현을 모르고 이 계약만 쓴다.
public protocol SecureStorage: Sendable {
  func save(_ value: String, for key: SecureStorageKey) throws(SecureStorageError)
  func load(_ key: SecureStorageKey) throws(SecureStorageError) -> String?
  func remove(_ key: SecureStorageKey) throws(SecureStorageError)
  func removeAll() throws(SecureStorageError)
}
