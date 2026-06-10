//
//  NotificationUseCase.swift
//  UseCase
//

import Foundation

import DomainInterface
import Entity

import ComposableArchitecture

public struct NotificationUseCaseImpl: NotificationInterface {
  @Dependency(\.notificationRepository) private var notificationRepository

  public init() {}

  public func fetchNotifications(
    category: NotificationCategory,
    page: Int,
    size: Int
  ) async throws -> NotificationPage {
    return try await notificationRepository.fetchNotifications(
      category: category,
      page: page,
      size: size
    )
  }

  public func fetchNotificationDetail(notificationId: Int) async throws -> NotificationDetail {
    return try await notificationRepository.fetchNotificationDetail(notificationId: notificationId)
  }

  public func markAsRead(notificationId: Int) async throws {
    try await notificationRepository.markAsRead(notificationId: notificationId)
  }

  public func markAllAsRead() async throws {
    try await notificationRepository.markAllAsRead()
  }
}

extension NotificationUseCaseImpl: DependencyKey {
  public static var liveValue = NotificationUseCaseImpl()
  public static var testValue = NotificationUseCaseImpl()
  public static var previewValue = NotificationUseCaseImpl()
}

public extension DependencyValues {
  var notificationUseCase: NotificationUseCaseImpl {
    get { self[NotificationUseCaseImpl.self] }
    set { self[NotificationUseCaseImpl.self] = newValue }
  }
}
