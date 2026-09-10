//
//  NotificationPage.swift
//  Entity
//

import Foundation

public struct NotificationPage: Equatable {
  public let items: [NotificationItem]
  public let hasNext: Bool

  public init(
    items: [NotificationItem],
    hasNext: Bool
  ) {
    self.items = items
    self.hasNext = hasNext
  }
}
