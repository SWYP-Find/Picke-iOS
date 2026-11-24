//
//  SearchRepositoryImpl.swift
//  SearchDomain
//
//  Created by Picke on 10/11/26.
//

import APIEndpoint
import BattleDomainInterface
import Dependencies
import Foundation
import HomeDomainInterface
import PickeNetwork
import SearchDomainInterface

public final class SearchRepositoryImpl: SearchInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func searchBattles(
    category: String?,
    sort: String?,
    offset: Int?,
    size: Int?
  ) async throws -> ExploreItemPage {
    do {
      let data = try await client.send(
        SearchService.battles(category: category, sort: sort, offset: offset, size: size),
        as: SearchBattlePageDataDTO.self
      )
      return data.toDomain()
    } catch {
      if case let .response(response) = error, response.isUnauthorized {
        throw BattleError.unauthorized
      }
      throw error
    }
  }
}
