//
//  NotificationInterface.swift
//  DomainInterface
//

import Entity
import Foundation
import WeaveDI

public protocol NotificationInterface: Sendable {
  func fetchNotifications(
    category: NotificationCategory,
    page: Int,
    size: Int
  ) async throws -> NotificationPage
  func fetchNotificationDetail(notificationId: Int) async throws -> NotificationDetail
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
