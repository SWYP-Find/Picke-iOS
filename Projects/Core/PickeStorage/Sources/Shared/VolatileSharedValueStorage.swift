//
//  VolatileSharedValueStorage.swift
//  PickeStorage
//
//  Created by Picke on 10/11/26.
//

import Foundation

import PickeStorageInterface

/// SQLite 준비에 실패한 실행에서도 앱이 돌아가게 하는 비영속 fallback.
final class VolatileSharedValueStorage: SharedValueStorage, @unchecked Sendable {
  let identifier = SharedValueStorageIdentifier()

  private let lock = NSLock()
  private var values: [String: Data] = [:]

  func load(forKey key: String) throws -> Data? {
    lock.withLock { values[key] }
  }

  func save(_ data: Data, forKey key: String) throws {
    lock.withLock { values[key] = data }
  }

  func remove(forKey key: String) throws {
    lock.withLock { values[key] = nil }
  }
}
