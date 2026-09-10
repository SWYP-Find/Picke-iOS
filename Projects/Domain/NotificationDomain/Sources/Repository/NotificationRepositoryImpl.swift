//
//  NotificationRepositoryImpl.swift
//  Repository
//

import Foundation

import Dependencies

import APIEndpoint
import PickeNetwork
import NotificationDomainInterface


public final class NotificationRepositoryImpl: NotificationInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchNotifications(
    category: NotificationCategory,
    page: Int,
    size: Int
  ) async throws -> NotificationPage {
    let data = try await client.send(
      NotificationService.list( query: NotificationsQueryRequest( category: category.rawValue, page: page, size: size ) ),
      as: NotificationDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchNotificationDetail(notificationId: Int) async throws -> NotificationDetail {
    let data = try await client.send(
      NotificationService.detail(notificationId: notificationId),
      as: NotificationDetailDTO.self
    )

    return data.toDomain()
  }

  public func hasUnreadNotifications() async throws -> Bool {
    let data = try await client.send(
      NotificationService.unread,
      as: NotificationUnreadDTO.self
    )
    return data.hasUnread ?? false
  }

  public func markAsRead(notificationId: Int) async throws {
    _ = try await client.send(
      NotificationService.read(notificationId: notificationId),
      as: PickeEmptyResponse.self
    )
  }

  /// PATCH /read-all — 서버가 처리 후 최신 미읽음 여부(`data.hasUnread`)를 반환한다. 그 값을 그대로 쓴다.
  public func markAllAsRead() async throws -> Bool {
    let data = try await client.send(
      NotificationService.readAll,
      as: NotificationUnreadDTO.self
    )
    return data.hasUnread ?? false
  }
}
