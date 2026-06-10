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
    self.isRead = isRead
    self.createdAt = createdAt
    self.readAt = readAt
  }
}
