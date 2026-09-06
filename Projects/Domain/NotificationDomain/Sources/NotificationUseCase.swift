//
//  NotificationUseCase.swift
//  UseCase
//

import Foundation

import NotificationDomainInterface

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

  public func hasUnreadNotifications() async throws -> Bool {
    return try await notificationRepository.hasUnreadNotifications()
  }

  public func markAsRead(notificationId: Int) async throws {
    try await notificationRepository.markAsRead(notificationId: notificationId)
  }

  public func markAllAsRead() async throws -> Bool {
    return try await notificationRepository.markAllAsRead()
  }
}
