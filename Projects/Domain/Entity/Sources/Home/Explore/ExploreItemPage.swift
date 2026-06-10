//
//  ExploreItemPage.swift
//  Entity
//

import Foundation

public struct ExploreItemPage: Equatable {
  public let items: [ExploreItem]
  public let nextOffset: Int?
  public let hasNext: Bool

  public init(
    items: [ExploreItem],
    nextOffset: Int?,
    hasNext: Bool
  ) {
    self.items = items
    self.nextOffset = nextOffset
    self.hasNext = hasNext
  }
}
