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
  /// 모두 읽음 처리 후 서버가 반환한 최신 미읽음 여부(hasUnread).
  func markAllAsRead() async throws -> Bool
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

// UseCase 소비자용 별칭 — 인터페이스 강제(구현 모듈 import 불필요). pass-through 라 리포지토리 키로 해소.
public extension DependencyValues {
  var notificationUseCase: NotificationInterface {
    get { self[NotificationRepositoryDependency.self] }
    set { self[NotificationRepositoryDependency.self] = newValue }
  }
}
