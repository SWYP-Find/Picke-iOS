//
//  SessionCacheInvalidator+Live.swift
//  DomainAssembly
//

import PickeStorageInterface

import Dependencies

// 로컬 캐시(LocalDataSource)를 두는 도메인이 생기면 여기서 clear 를 엮는다.
// 지금은 비울 대상이 없어 계약만 살아 있고 실제 동작은 없다.
extension SessionCacheInvalidatorDependency: DependencyKey {
  public static var liveValue: any SessionCacheInvalidating {
    NoopSessionCacheInvalidator()
  }
}
