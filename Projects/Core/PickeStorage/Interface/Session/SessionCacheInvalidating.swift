//
//  SessionCacheInvalidating.swift
//  PickeStorageInterface
//

import Dependencies

/// 세션이 끊길 때(로그아웃·탈퇴·토큰 만료) 계정에 묶인 로컬 캐시를 비우는 계약.
public protocol SessionCacheInvalidating: Sendable {
  func invalidate() async
}

/// 비울 로컬 캐시가 아직 없는 구성에서 쓰는 기본 구현.
public struct NoopSessionCacheInvalidator: SessionCacheInvalidating {
  public init() {}

  public func invalidate() async {}
}

public enum SessionCacheInvalidatorDependency: TestDependencyKey {
  public static let testValue: any SessionCacheInvalidating = NoopSessionCacheInvalidator()
  public static let previewValue: any SessionCacheInvalidating = NoopSessionCacheInvalidator()
}

public extension DependencyValues {
  var sessionCacheInvalidator: any SessionCacheInvalidating {
    get { self[SessionCacheInvalidatorDependency.self] }
    set { self[SessionCacheInvalidatorDependency.self] = newValue }
  }
}
