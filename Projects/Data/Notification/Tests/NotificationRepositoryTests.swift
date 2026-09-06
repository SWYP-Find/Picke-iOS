//
//  NotificationRepositoryTests.swift
//  NotificationDataTests
//

import Foundation
import Testing

@testable import NotificationData

import APIEndpoint
import NotificationDomainInterface

struct NotificationRepositoryTests {
  @Test
  func fetchNotifications_decodesItemsAndMapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "items": [
          {
            "notificationId": 1,
            "category": "CONTENT",
            "detailCode": "NEW_BATTLE",
            "title": "새로운 배틀이 시작되었어요",
            "body": "지금 참여해보세요",
            "referenceId": 10,
            "perspectiveId": null,
            "isRead": false,
            "createdAt": "2026-07-10T12:00:00Z"
          }
        ],
        "hasNext": true
      },
      "error": null
    }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    let page = try await repo.fetchNotifications(category: .all, page: 0, size: 20)

    #expect(page.hasNext == true)
    #expect(page.items.count == 1)
    let item = try #require(page.items.first)
    #expect(item.notificationId == 1)
    #expect(item.category == .content)
    #expect(item.detailCode == "NEW_BATTLE")
    #expect(item.title == "새로운 배틀이 시작되었어요")
    #expect(item.body == "지금 참여해보세요")
    #expect(item.referenceId == 10)
    #expect(item.perspectiveId == nil)
    #expect(item.isRead == false)
    #expect(item.createdAt != nil)
  }

  @Test
  func fetchNotifications_withMissingItems_mapsToEmptyList() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "hasNext": false
      },
      "error": null
    }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    let page = try await repo.fetchNotifications(category: .all, page: 0, size: 20)

    #expect(page.items.isEmpty)
    #expect(page.hasNext == false)
  }

  @Test
  func fetchNotifications_withNullData_throwsBackendError() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": null,
      "error": { "code": "NOT_FOUND", "message": "알림이 없습니다" }
    }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    await #expect(throws: NotificationError.backendError("알림이 없습니다")) {
      try await repo.fetchNotifications(category: .all, page: 0, size: 20)
    }
  }

  @Test
  func fetchNotificationDetail_decodesAndMapsToDomain() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "notificationId": 5,
        "category": "NOTICE",
        "detailCode": "SYSTEM_NOTICE",
        "title": "공지",
        "body": "점검 안내",
        "referenceId": null,
        "perspectiveId": null,
        "isRead": true,
        "createdAt": "2026-07-01T09:00:00Z",
        "readAt": "2026-07-02T09:00:00Z"
      },
      "error": null
    }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    let detail = try await repo.fetchNotificationDetail(notificationId: 5)

    #expect(detail.notificationId == 5)
    #expect(detail.category == .notice)
    #expect(detail.detailCode == "SYSTEM_NOTICE")
    #expect(detail.title == "공지")
    #expect(detail.body == "점검 안내")
    #expect(detail.referenceId == nil)
    #expect(detail.isRead == true)
    #expect(detail.createdAt != nil)
    #expect(detail.readAt != nil)
  }

  @Test
  func fetchNotificationDetail_withNullData_throwsBackendError() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": null,
      "error": { "code": "NOT_FOUND", "message": "알림 상세가 없습니다" }
    }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    await #expect(throws: NotificationError.backendError("알림 상세가 없습니다")) {
      try await repo.fetchNotificationDetail(notificationId: 5)
    }
  }

  @Test
  func hasUnreadNotifications_returnsTrue_whenHasUnreadIsTrue() async throws {
    let json = """
    { "statusCode": 200, "data": { "hasUnread": true }, "error": null }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    let hasUnread = try await repo.hasUnreadNotifications()

    #expect(hasUnread == true)
  }

  @Test
  func hasUnreadNotifications_returnsFalse_whenHasUnreadIsFalse() async throws {
    let json = """
    { "statusCode": 200, "data": { "hasUnread": false }, "error": null }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    let hasUnread = try await repo.hasUnreadNotifications()

    #expect(hasUnread == false)
  }

  @Test
  func hasUnreadNotifications_withNullData_defaultsToFalse() async throws {
    let json = """
    { "statusCode": 200, "data": null, "error": null }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    let hasUnread = try await repo.hasUnreadNotifications()

    #expect(hasUnread == false)
  }

  @Test
  func markAsRead_doesNotThrow_onSuccessResponse() async throws {
    let json = """
    { "statusCode": 200, "data": "OK", "error": null }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    try await repo.markAsRead(notificationId: 1)
  }

  @Test
  func markAllAsRead_doesNotThrow_onSuccessResponse() async throws {
    let json = """
    { "statusCode": 200, "data": "OK", "error": null }
    """
    let repo = NotificationRepositoryImpl(
      provider: StubNetworkProvider<NotificationService>(stubData: Data(json.utf8))
    )

    try await repo.markAllAsRead()
  }
}
