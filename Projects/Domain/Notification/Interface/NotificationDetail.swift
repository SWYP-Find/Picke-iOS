//
//  NotificationDetail.swift
//  Entity
//
//  알림 단건 상세 — `GET /api/v1/notifications/{id}` (목록 항목 + readAt).
//

import Foundation

public struct NotificationDetail: Equatable, Identifiable {
  public let notificationId: Int
  public let category: NotificationCategory
  public let detailCode: String
  public let title: String
  public let body: String
  public let referenceId: Int?
  /// COMMENT_LIKE / NEW_COMMENT 에서 관점(댓글) 화면 이동용. 그 외 nil.
  public let perspectiveId: Int?
  public let isRead: Bool
  public let createdAt: Date?
  public let readAt: Date?

  public var id: Int { notificationId }

  public init(
    notificationId: Int,
    category: NotificationCategory,
    detailCode: String,
    title: String,
    body: String,
    referenceId: Int?,
    perspectiveId: Int?,
    isRead: Bool,
    createdAt: Date?,
    readAt: Date?
  ) {
    self.notificationId = notificationId
    self.category = category
    self.detailCode = detailCode
    self.title = title
    self.body = body
    self.referenceId = referenceId
    self.perspectiveId = perspectiveId
    self.isRead = isRead
    self.createdAt = createdAt
    self.readAt = readAt
  }
}
