//
//  ShareItem.swift
//  PickeCoreUtility
//

import Foundation

public struct ShareItem: Equatable, Identifiable, @unchecked Sendable {
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
