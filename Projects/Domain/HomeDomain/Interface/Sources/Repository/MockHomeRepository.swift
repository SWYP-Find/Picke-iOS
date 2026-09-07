//
//  MockHomeRepository.swift
//  DomainInterface
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

/// Home Repository 기본 구현체 — 미주입 환경에서 mock 번들을 반환한다.
public final class MockHomeRepository: HomeInterface, @unchecked Sendable {
  public init() {}

  public func fetchHome() async throws -> HomeBundle {
    .mock
  }
}
