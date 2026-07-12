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
