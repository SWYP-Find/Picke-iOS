//
//  CreditHistoryPage.swift
//  Entity
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
