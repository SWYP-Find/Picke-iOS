//
//  NotificationPage.swift
//  Entity
//
//  `GET /api/v1/notifications` 응답 (page 기반 페이지네이션).
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
