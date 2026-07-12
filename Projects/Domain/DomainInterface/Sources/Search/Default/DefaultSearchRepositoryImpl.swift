//
//  DefaultSearchRepositoryImpl.swift
//  DomainInterface
//

import Entity
import Foundation

public struct DefaultSearchRepositoryImpl: SearchInterface {
  public init() {}

  public func searchBattles(
    category _: String?,
    sort _: String?,
    offset _: Int?,
    size _: Int?
  ) async throws -> ExploreItemPage {
    ExploreItemPage(items: [], nextOffset: nil, hasNext: false)
  }
}
