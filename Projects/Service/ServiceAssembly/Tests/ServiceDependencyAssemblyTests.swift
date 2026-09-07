//
//  ServiceDependencyAssemblyTests.swift
//  ServiceAssemblyTests
//

import Foundation
import Testing

@testable import ServiceAssembly

import CoreAssembly
import PickeAuthInterface
import PickeNetworkInterface
import PickeStorageInterface

import Dependencies

struct ServiceDependencyAssemblyTests {
  /// 조립을 매번 새로 만들면 인증 세션이 갈라져 한쪽만 토큰을 갱신한다.
  @Test
  func 네트워크_컨테이너는_같은_인스턴스를_계속_내준다() {
    #expect(NetworkContainer.authenticatedClient as AnyObject === NetworkContainer.authenticatedClient as AnyObject)
    #expect(NetworkContainer.authService as AnyObject === NetworkContainer.authService as AnyObject)
  }

  /// 앱 부팅 시 이 한 번의 등록으로 네트워크·인증이 모두 live 로 바뀌어야 한다.
  @Test
  func register_는_네트워크와_인증을_한번에_등록한다() throws {
    var values = DependencyValues()
    ServiceDependencyAssembly.register(into: &values)

    #expect(values.networkClient as AnyObject === NetworkContainer.authenticatedClient as AnyObject)
    #expect(values.authService as AnyObject === NetworkContainer.authService as AnyObject)
    // 저장소 조립도 함께 타야 공유 값이 앱 재실행 후에도 남는다.
    let key = "ServiceDependencyAssemblyTests-\(UUID().uuidString)"
    try values.sharedValueStorage.save(Data("값".utf8), forKey: key)
    defer { try? values.sharedValueStorage.remove(forKey: key) }
  }

  @Test
  func 인증_클라이언트가_liveValue_로_노출된다() {
    #expect(NetworkClientDependency.liveValue as AnyObject === NetworkContainer.authenticatedClient as AnyObject)
    #expect(AuthServiceDependency.liveValue as AnyObject === NetworkContainer.authService as AnyObject)
  }
}
