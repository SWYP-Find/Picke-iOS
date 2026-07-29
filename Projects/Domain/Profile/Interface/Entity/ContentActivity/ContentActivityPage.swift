//
//  ContentActivityPage.swift
//  Entity
//

import Foundation

public struct ContentActivityPage: Equatable {
  public let items: [ContentActivity]
  public let nextOffset: Int
  public let hasNext: Bool

  public init(
    items: [ContentActivity],
    nextOffset: Int,
    hasNext: Bool
  ) {
    self.items = items
    self.nextOffset = nextOffset
    self.hasNext = hasNext
  }
}
