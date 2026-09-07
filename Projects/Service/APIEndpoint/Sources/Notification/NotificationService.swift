//
//  NotificationService.swift
//  Service
//

import Foundation

import API
import PickeNetwork

public enum NotificationService {
  case list(query: NotificationsQueryRequest)
  case unread
  case detail(notificationId: Int)
  case read(notificationId: Int)
  case readAll
}

extension NotificationService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.notification }

  public var path: String {
    switch self {
    case .list:
      return NotificationAPI.list.description
    case .unread:
      return NotificationAPI.unread.description
    case let .detail(notificationId):
      return NotificationAPI.detail(notificationId: notificationId).description
    case let .read(notificationId):
      return NotificationAPI.read(notificationId: notificationId).description
    case .readAll:
      return NotificationAPI.readAll.description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .list, .unread, .detail:
      return .get
    case .read, .readAll:
      return .patch
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .list(query):
      return query
    case .unread, .detail, .read, .readAll:
      return nil
    }
  }
}
