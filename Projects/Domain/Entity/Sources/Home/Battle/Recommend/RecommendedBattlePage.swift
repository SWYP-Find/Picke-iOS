//
//  RecommendedBattlePage.swift
//  Entity
//

import Foundation

public struct RecommendedBattlePage: Equatable {
  public let items: [RecommendedBattle]
  public let nextCursor: String?
  public let hasNext: Bool

  public init(
    items: [RecommendedBattle],
    nextCursor: String?,
    hasNext: Bool
  ) {
    self.items = items
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }
}
