//
//  NotificationRepositoryImpl.swift
//  Repository
//

import Foundation

import Model
import NotificationDomainInterface
import Repository

import LogMacro
import Moya

@preconcurrency import AsyncMoya

public final class NotificationRepositoryImpl: NotificationInterface, @unchecked Sendable {
  private let provider: MoyaProvider<NotificationService>

  public init(
    provider: MoyaProvider<NotificationService> = MoyaProvider<NotificationService>.authorized
  ) {
    self.provider = provider
  }

  public func fetchNotifications(
    category: NotificationCategory,
    page: Int,
    size: Int
  ) async throws -> NotificationPage {
    let dto: NotificationResponseDTO = try await provider.request(
      .list(
        query: NotificationsQueryRequest(
          category: category.rawValue,
          page: page,
          size: size
        )
      )
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "알림 응답이 비어 있습니다"
      Log.error("[NotificationRepositoryImpl] empty notifications payload: \(message)")
      throw NotificationError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchNotificationDetail(notificationId: Int) async throws -> NotificationDetail {
    let dto: NotificationDetailResponseDTO = try await provider.request(
      .detail(notificationId: notificationId)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "알림 상세 응답이 비어 있습니다"
      Log.error("[NotificationRepositoryImpl] empty notification detail payload: \(message)")
      throw NotificationError.backendError(message)
    }

    return data.toDomain()
  }

  public func hasUnreadNotifications() async throws -> Bool {
    let dto: NotificationUnreadResponseDTO = try await provider.request(.unread)
    return dto.data?.hasUnread ?? false
  }

  public func markAsRead(notificationId: Int) async throws {
    let _: BaseResponseDTO<String> = try await provider.request(
      .read(notificationId: notificationId)
    )
  }

  public func markAllAsRead() async throws {
    let _: BaseResponseDTO<String> = try await provider.request(.readAll)
  }
}
