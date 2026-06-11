//
//  NotificationDataDTO+.swift
//  Model
//

import Entity
import Foundation

public extension NotificationDataDTO {
  func toDomain() -> NotificationPage {
    NotificationPage(
      items: (items ?? []).map { $0.toDomain() },
      hasNext: hasNext ?? false
    )
  }
}

public extension NotificationItemDTO {
  func toDomain() -> NotificationItem {
    NotificationItem(
      notificationId: notificationId ?? 0,
      category: NotificationCategory(rawValue: category ?? ""),
      detailCode: detailCode ?? "",
      title: title ?? "",
      body: body ?? "",
      referenceId: referenceId,
      perspectiveId: perspectiveId,
      isRead: isRead ?? false,
      createdAt: createdAt.flatMap(NotificationDateParser.parseISO8601)
    )
  }
}

public extension NotificationDetailDTO {
  func toDomain() -> NotificationDetail {
    NotificationDetail(
      notificationId: notificationId ?? 0,
      category: NotificationCategory(rawValue: category ?? ""),
      detailCode: detailCode ?? "",
      title: title ?? "",
      body: body ?? "",
      referenceId: referenceId,
      perspectiveId: perspectiveId,
      isRead: isRead ?? false,
      createdAt: createdAt.flatMap(NotificationDateParser.parseISO8601),
      readAt: readAt.flatMap(NotificationDateParser.parseISO8601)
    )
  }
}

enum NotificationDateParser {
  static func parseISO8601(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value)
  }
}
