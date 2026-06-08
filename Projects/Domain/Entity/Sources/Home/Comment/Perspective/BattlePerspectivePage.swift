//
//  BattlePerspectivePage.swift
//  Entity
//

import Foundation

public struct BattlePerspectivePage: Equatable {
  public let items: [BattlePerspective]
  public let nextCursor: String?
  public let hasNext: Bool

  public init(
    items: [BattlePerspective],
    nextCursor: String?,
    hasNext: Bool
  ) {
    self.items = items
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }
}
