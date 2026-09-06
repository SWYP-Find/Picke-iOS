//
//  SearchRepositoryImpl.swift
//  Repository
//

import Foundation

import APIEndpoint
import HomeDomainInterface
import Model
import NetworkModule
import SearchDomainInterface

import LogMacro
import BattleDomainInterface


public final class SearchRepositoryImpl: SearchInterface, @unchecked Sendable {
  private let provider: any NetworkProviding<SearchService>

  public init(
    provider: any NetworkProviding<SearchService> = AlamofireNetworkProvider<SearchService>.authorized
  ) {
    self.provider = provider
  }

  public func searchBattles(
    category: String?,
    sort: String?,
    offset: Int?,
    size: Int?
  ) async throws -> ExploreItemPage {
    let dto: SearchBattlePageResponseDTO = try await provider.request(
      .battles(category: category, sort: sort, offset: offset, size: size)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "배틀 검색 응답이 비어 있습니다"
      Log.error("[SearchRepositoryImpl] empty searchBattles payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }
}
