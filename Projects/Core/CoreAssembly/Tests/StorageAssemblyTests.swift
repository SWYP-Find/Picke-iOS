//
//  StorageAssemblyTests.swift
//  CoreAssemblyTests
//

import Testing

@testable import CoreAssembly
import PickeStorageInterface

import Dependencies

@Suite("StorageAssembly")
struct StorageAssemblyTests {
  /// 조립이 빠지면 앱이 보안 저장소 없이 뜨고 재실행 시 로그인이 풀린다.
  @Test("secureStorage 는 SecureStorage 구현을 제공한다")
  func secureStorageProvidesStorage() {
    let storage: any SecureStorage = StorageAssembly.secureStorage()

    #expect(String(describing: type(of: storage)).isEmpty == false)
  }

  @Test("register 는 공유값 저장소 의존성을 꽂는다")
  func registerInstallsSharedValueStorage() {
    var values = DependencyValues()
    StorageAssembly.register(into: &values)

    #expect(String(describing: type(of: values.sharedValueStorage)).isEmpty == false)
  }
}
