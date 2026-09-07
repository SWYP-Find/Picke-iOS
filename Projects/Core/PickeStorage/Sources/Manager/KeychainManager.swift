//
//  KeychainManager.swift
//  PickeStorage
//
//  Created by Wonji Suh  on 1/2/26.
//

import Foundation
import OSLog

@_exported import PickeStorageInterface

/// `SecureStorage` 위에 얹은 토큰 전용 어댑터.
///
/// Security 프레임워크 호출은 `KeychainStorage` 가 전담하고,
/// 여기서는 access/refresh token 이라는 앱의 어휘만 다룬다.
public struct KeychainManager: KeychainManaging {
  private let storage: any SecureStorage
  private let logger = Logger(subsystem: "io.Picke.co", category: "keychain")

  public init(storage: any SecureStorage = StorageFactory.secureStorage) {
    self.storage = storage
  }

  public func save(
    accessToken: String,
    refreshToken: String
  ) {
    saveAccessToken(accessToken)
    saveRefreshToken(refreshToken)
  }

  public func saveAccessToken(_ token: String) {
    write(token, for: .accessToken)
  }

  public func clearAccessToken() {
    remove(.accessToken)
  }

  public func saveRefreshToken(_ token: String) {
    write(token, for: .refreshToken)
  }

  public func accessToken() -> String? {
    read(.accessToken)
  }

  public func refreshToken() -> String? {
    read(.refreshToken)
  }

  public func clear() {
    do {
      try storage.removeAll()
    } catch {
      logger.error("토큰 전체 삭제 실패: \(String(describing: error), privacy: .public)")
    }
  }

  private func write(_ value: String, for key: SecureStorageKey) {
    do {
      try storage.save(value, for: key)
    } catch {
      logger.error("\(key.rawValue, privacy: .public) 저장 실패: \(String(describing: error), privacy: .public)")
    }
  }

  private func read(_ key: SecureStorageKey) -> String? {
    do {
      return try storage.load(key)
    } catch {
      logger.error("\(key.rawValue, privacy: .public) 조회 실패: \(String(describing: error), privacy: .public)")
      return nil
    }
  }

  private func remove(_ key: SecureStorageKey) {
    do {
      try storage.remove(key)
    } catch {
      logger.error("\(key.rawValue, privacy: .public) 삭제 실패: \(String(describing: error), privacy: .public)")
    }
  }
}
