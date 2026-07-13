//
//  DefaultNotificationRepositoryImpl.swift
//  DomainInterface
//

import Foundation

public struct DefaultNotificationRepositoryImpl: NotificationInterface {
  public init() {}

  public func fetchNotifications(
    category _: NotificationCategory,
    page _: Int,
    size _: Int
  ) async throws -> NotificationPage {
    NotificationPage(items: [], hasNext: false)
  }

  public func fetchNotificationDetail(notificationId: Int) async throws -> NotificationDetail {
    NotificationDetail(
      notificationId: notificationId,
      category: .all,
      detailCode: "",
      title: "",
      body: "",
      referenceId: nil,
      perspectiveId: nil,
      isRead: false,
      createdAt: nil,
      readAt: nil
    )
  }

  public func hasUnreadNotifications() async throws -> Bool { false }

  public func markAsRead(notificationId _: Int) async throws {}

  public func markAllAsRead() async throws -> Bool { false }
}
