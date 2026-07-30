//
//  KeychainManagerInterface.swift
//  PickeStorageInterface
//
//  Created by Wonji Suh  on 1/2/26.
//

import Foundation
import WeaveDI

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

public struct KeychainManagerDependency: DependencyKey {
  public static var liveValue: KeychainManaging {
    return UnifiedDI.resolve(KeychainManaging.self) ?? InMemoryKeychainManager()
  }

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
