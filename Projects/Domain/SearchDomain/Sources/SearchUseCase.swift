//
//  SearchUseCase.swift
//  UseCase
//

import Foundation

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

