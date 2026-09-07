//
//  SearchRepositoryImpl.swift
//  Repository
//

import Foundation

import Dependencies

import APIEndpoint
import HomeDomainInterface
import PickeNetwork
import SearchDomainInterface

import BattleDomainInterface

public final class SearchRepositoryImpl: SearchInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func searchBattles(
    category: String?,
    sort: String?,
    offset: Int?,
    size: Int?
  ) async throws -> ExploreItemPage {
    let data = try await client.send(
      SearchService.battles(category: category, sort: sort, offset: offset, size: size),
      as: SearchBattlePageDataDTO.self
    )

    return data.toDomain()
  }
}
