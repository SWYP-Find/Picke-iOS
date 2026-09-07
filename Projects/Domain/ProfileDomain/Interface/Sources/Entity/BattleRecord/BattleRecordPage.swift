//
//  BattleRecordPage.swift
//  Entity
//

import Foundation

public struct BattleRecordPage: Equatable {
  public let items: [BattleRecord]
  public let nextOffset: Int
  public let hasNext: Bool

  public init(
    items: [BattleRecord],
    nextOffset: Int,
    hasNext: Bool
  ) {
    self.items = items
    self.nextOffset = nextOffset
    self.hasNext = hasNext
  }
}
