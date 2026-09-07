//
//  StorageAssemblyTests.swift
//  CoreAssemblyTests
//

import Foundation
import Testing

@testable import CoreAssembly
import PickeStorage
import PickeStorageInterface

import Dependencies

struct StorageAssemblyTests {
  /// 등록을 빼먹으면 공유 값 경로가 Unimplemented 기본값에 걸려 전부 throw 한다.
  /// 실제 읽고 쓰는 데까지 가봐야 그 누락이 드러난다.
  @Test
  func register_후에는_공유값을_실제로_읽고_쓴다() throws {
    var values = DependencyValues()
    StorageAssembly.register(into: &values)
    let storage = values.sharedValueStorage
    let key = "StorageAssemblyTests-\(UUID().uuidString)"
    let payload = Data("값".utf8)

    try storage.save(payload, forKey: key)
    defer { try? storage.remove(forKey: key) }

    #expect(try storage.load(forKey: key) == payload)
  }

  @Test
  func secureStorage_는_Keychain_구현을_내놓는다() {
    #expect(StorageAssembly.secureStorage() is KeychainStorage)
  }
}
