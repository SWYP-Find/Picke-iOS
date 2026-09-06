//
//  NotificationRequestMappingTests.swift
//  NotificationDataTests
//

import Foundation
import Testing

@testable import NotificationData

import API
import APIEndpoint
import PickeNetwork

struct NotificationRequestMappingTests {
  @Test
  func list_request_isGETWithQueryParameters() throws {
    let service = NotificationService.list(
      query: NotificationsQueryRequest(category: "ALL", page: 1, size: 20)
    )
    let request = try service.asURLRequest()

    #expect(service.urlPath == NotificationAPI.list.description)
    #expect(service.method == .get)
    #expect(request.url?.path == "/api/v1/notifications")
    #expect(request.httpBody == nil)

    let query = request.url?.query ?? ""
    #expect(query.contains("category=ALL"))
    #expect(query.contains("page=1"))
    #expect(query.contains("size=20"))
  }

  @Test
  func list_request_withEmptyQuery_hasNoQueryString() throws {
    let service = NotificationService.list(query: NotificationsQueryRequest())
    let request = try service.asURLRequest()

    #expect(service.parameters == nil)
    #expect(request.url?.query == nil)
  }

  @Test
  func unread_request_isGETWithNoParameters() throws {
    let service = NotificationService.unread
    let request = try service.asURLRequest()

    #expect(service.urlPath == NotificationAPI.unread.description)
    #expect(service.method == .get)
    #expect(request.url?.path == "/api/v1/notifications/unread")
    #expect(service.parameters == nil)
    #expect(request.httpBody == nil)
  }

  @Test
  func detail_request_isGETWithNoParameters() throws {
    let service = NotificationService.detail(notificationId: 42)
    let request = try service.asURLRequest()

    #expect(service.urlPath == NotificationAPI.detail(notificationId: 42).description)
    #expect(service.method == .get)
    #expect(request.url?.path == "/api/v1/notifications/42")
    #expect(service.parameters == nil)
    #expect(request.httpBody == nil)
  }

  @Test
  func read_request_isPATCHWithNoParameters() throws {
    let service = NotificationService.read(notificationId: 42)
    let request = try service.asURLRequest()

    #expect(service.urlPath == NotificationAPI.read(notificationId: 42).description)
    #expect(service.method == .patch)
    #expect(request.url?.path == "/api/v1/notifications/42/read")
    #expect(service.parameters == nil)
    #expect(request.httpBody == nil)
  }

  @Test
  func readAll_request_isPATCHWithNoParameters() throws {
    let service = NotificationService.readAll
    let request = try service.asURLRequest()

    #expect(service.urlPath == NotificationAPI.readAll.description)
    #expect(service.method == .patch)
    #expect(request.url?.path == "/api/v1/notifications/read-all")
    #expect(service.parameters == nil)
    #expect(request.httpBody == nil)
  }

  @Test
  func allCases_includeBaseHeaderFields() throws {
    let services: [NotificationService] = [
      .list(query: NotificationsQueryRequest()),
      .unread,
      .detail(notificationId: 1),
      .read(notificationId: 1),
      .readAll,
    ]

    for service in services {
      let request = try service.asURLRequest()
      #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
      #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true)
    }
  }
}
