//
//  KeychainManagerInterface.swift
//  PickeStorageInterface
//
//  Created by Wonji Suh  on 1/2/26.
//

import Foundation

import Dependencies

public protocol KeychainManaging: Sendable {
  func save(
    accessToken: String,
    refreshToken: String
  )
  func saveAccessToken(_ token: String)
  func clearAccessToken()
  func saveRefreshToken(_ token: String)
  func accessToken() -> String?
  func refreshToken() -> String?
  func clear()
}

/// 라이브 구현(`KeychainManager`)은 PickeStorage 에서 `DependencyKey` 로 이어 붙인다.
public enum KeychainManagerDependency: TestDependencyKey {
  public static var testValue: KeychainManaging {
    return InMemoryKeychainManager()
  }

  public static var previewValue: KeychainManaging = testValue
}

public extension DependencyValues {
  var keychainManager: KeychainManaging {
    get { self[KeychainManagerDependency.self] }
    set { self[KeychainManagerDependency.self] = newValue }
  }
}
