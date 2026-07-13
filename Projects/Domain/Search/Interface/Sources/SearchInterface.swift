//
//  SearchInterface.swift
//  DomainInterface
//

import Entity
import Foundation
import HomeDomainInterface
import WeaveDI

public protocol SearchInterface: Sendable {
  func searchBattles(
    category: String?,
    sort: String?,
    offset: Int?,
    size: Int?
  ) async throws -> ExploreItemPage
}

public struct SearchRepositoryDependency: DependencyKey {
  public static var liveValue: SearchInterface {
    UnifiedDI.resolve(SearchInterface.self) ?? DefaultSearchRepositoryImpl()
  }

  public static var testValue: SearchInterface {
    UnifiedDI.resolve(SearchInterface.self) ?? DefaultSearchRepositoryImpl()
  }

  public static var previewValue: SearchInterface = liveValue
}

public extension DependencyValues {
  var searchRepository: SearchInterface {
    get { self[SearchRepositoryDependency.self] }
    set { self[SearchRepositoryDependency.self] = newValue }
  }
}

// UseCase 소비자용 별칭 — 인터페이스 강제(구현 모듈 import 불필요). pass-through 라 리포지토리 키로 해소.
public extension DependencyValues {
  var searchUseCase: SearchInterface {
    get { self[SearchRepositoryDependency.self] }
    set { self[SearchRepositoryDependency.self] = newValue }
  }
}
