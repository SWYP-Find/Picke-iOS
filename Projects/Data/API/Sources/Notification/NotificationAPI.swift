//
//  NotificationAPI.swift
//  API
//
//  알림(notifications) 엔드포인트 경로. (domain = "api/v1/notifications")
//

import Foundation

public enum NotificationAPI {
  /// GET /api/v1/notifications
  case list
  /// GET /api/v1/notifications/unread
  case unread
  /// GET /api/v1/notifications/{notificationId}
  case detail(notificationId: Int)
  /// PATCH /api/v1/notifications/{notificationId}/read
  case read(notificationId: Int)
  /// PATCH /api/v1/notifications/read-all
  case readAll

  public var description: String {
    switch self {
    case .list:
      return ""
    case .unread:
      return "/unread"
    case let .detail(notificationId):
      return "/\(notificationId)"
    case let .read(notificationId):
      return "/\(notificationId)/read"
    case .readAll:
      return "/read-all"
    }
  }
}
