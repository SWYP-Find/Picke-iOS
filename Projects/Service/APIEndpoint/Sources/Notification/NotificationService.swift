//
//  NotificationService.swift
//  Service
//

import Foundation

import API
import NetworkHeader


public enum NotificationService {
  case list(query: NotificationsQueryRequest)
  case unread
  case detail(notificationId: Int)
  case read(notificationId: Int)
  case readAll
}

extension NotificationService: PickeTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .notification }

  public var urlPath: String {
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

  public var parameters: [String: Any]? {
    switch self {
    case let .list(query):
      guard let dict = query.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    case .unread, .detail, .read, .readAll:
      return nil
    }
  }

  public var headers: [String: String]? {
    return APIHeader.baseHeader
  }
}
