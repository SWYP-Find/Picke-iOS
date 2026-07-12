//
//  ContentActivityPage.swift
//  Entity
//
//  `GET /api/v1/me/content-activities` 응답 (offset 페이지네이션).
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
