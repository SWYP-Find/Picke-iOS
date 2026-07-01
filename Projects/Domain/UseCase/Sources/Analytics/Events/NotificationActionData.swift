//
//  NotificationActionData.swift
//  UseCase
//

import Foundation

public enum NotificationActionType: String, Sendable {
  case viewList = "view_list"
  case readAll = "read_all"
  case itemTap = "item_tap"
}

public struct NotificationActionData: Sendable {
  public let action: NotificationActionType
  public let unreadCount: Int?

  public init(action: NotificationActionType, unreadCount: Int? = nil) {
    self.action = action
    self.unreadCount = unreadCount
  }
}
