//
//  BattleRecordPage.swift
//  Entity
//
//  `GET /api/v1/me/battle-records` 응답 (offset 페이지네이션).
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
