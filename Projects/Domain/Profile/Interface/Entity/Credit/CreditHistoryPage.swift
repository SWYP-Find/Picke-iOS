//
//  CreditHistoryPage.swift
//  Entity
//
//  `GET /api/v1/me/credits/history` 응답 (offset 페이지네이션).
//

import Foundation

public struct CreditHistoryPage: Equatable {
  public let items: [CreditHistoryItem]
  public let nextOffset: Int
  public let hasNext: Bool

  public init(
    items: [CreditHistoryItem],
    nextOffset: Int,
    hasNext: Bool
  ) {
    self.items = items
    self.nextOffset = nextOffset
    self.hasNext = hasNext
  }
}
