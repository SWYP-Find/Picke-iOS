//
//  SearchUseCase.swift
//  UseCase
//

import Foundation

import Entity
import HomeDomainInterface
import SearchDomainInterface

import ComposableArchitecture

public struct SearchUseCaseImpl: SearchInterface {
  @Dependency(\.searchRepository) private var searchRepository

  public init() {}

  public func searchBattles(
    category: String?,
    sort: String?,
    offset: Int?,
    size: Int?
  ) async throws -> ExploreItemPage {
    return try await searchRepository.searchBattles(
      category: category,
      sort: sort,
      offset: offset,
      size: size
    )
  }
}

extension SearchUseCaseImpl: DependencyKey {
  public static var liveValue = SearchUseCaseImpl()
  public static var testValue = SearchUseCaseImpl()
  public static var previewValue = SearchUseCaseImpl()
}

public extension DependencyValues {
  var searchUseCase: SearchUseCaseImpl {
    get { self[SearchUseCaseImpl.self] }
    set { self[SearchUseCaseImpl.self] = newValue }
  }
}
