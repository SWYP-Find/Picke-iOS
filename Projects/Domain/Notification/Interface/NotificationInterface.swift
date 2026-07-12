//
//  NotificationInterface.swift
//  DomainInterface
//

import Foundation
import WeaveDI

public protocol NotificationInterface: Sendable {
  func fetchNotifications(
    category: NotificationCategory,
    page: Int,
    size: Int
  ) async throws -> NotificationPage
  func fetchNotificationDetail(notificationId: Int) async throws -> NotificationDetail
  /// 벨 배지용 — 전체 기준 미읽음 알림 존재 여부.
  func hasUnreadNotifications() async throws -> Bool
  func markAsRead(notificationId: Int) async throws
  func markAllAsRead() async throws
}

public struct NotificationRepositoryDependency: DependencyKey {
  public static var liveValue: NotificationInterface {
    UnifiedDI.resolve(NotificationInterface.self) ?? DefaultNotificationRepositoryImpl()
  }

  public static var testValue: NotificationInterface {
    UnifiedDI.resolve(NotificationInterface.self) ?? DefaultNotificationRepositoryImpl()
  }

  public static var previewValue: NotificationInterface = liveValue
}

public extension DependencyValues {
  var notificationRepository: NotificationInterface {
    get { self[NotificationRepositoryDependency.self] }
    set { self[NotificationRepositoryDependency.self] = newValue }
  }
}
