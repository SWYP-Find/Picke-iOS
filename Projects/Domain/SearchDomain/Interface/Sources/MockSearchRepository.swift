//
//  MockSearchRepository.swift
//  SearchDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation
import HomeDomainInterface

public struct MockSearchRepository: SearchInterface {
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
