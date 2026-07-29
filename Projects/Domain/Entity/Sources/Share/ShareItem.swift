//
//  ShareItem.swift
//  Entity
//

import Foundation

public struct ShareItem: Equatable, Identifiable {
  public let id: UUID
  public let items: [Any]

  public init(
    id: UUID = UUID(),
    items: [Any]
  ) {
    self.id = id
    self.items = items
  }

  public static func == (lhs: ShareItem, rhs: ShareItem) -> Bool {
    lhs.id == rhs.id
  }
}
