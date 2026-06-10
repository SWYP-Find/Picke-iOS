//
//  PerspectiveCommentPage.swift
//  Entity
//

import Foundation

public struct PerspectiveCommentPage: Equatable {
  public let items: [PerspectiveComment]
  public let nextCursor: String?
  public let hasNext: Bool

  public init(
    items: [PerspectiveComment],
    nextCursor: String?,
    hasNext: Bool
  ) {
    self.items = items
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }
}
