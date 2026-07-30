//
//  DefaultSearchRepositoryImpl.swift
//  DomainInterface
//

import Foundation
import HomeDomainInterface

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
