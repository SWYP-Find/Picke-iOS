//
//  NotificationsQueryRequest.swift
//  Service
//
//  GET /api/v1/notifications 쿼리 파라미터.
//

import Foundation

public struct NotificationsQueryRequest: Encodable {
  /// ALL / CONTENT / NOTICE / EVENT.
  public let category: String?
  public let page: Int?
  public let size: Int?

  public init(
    category: String? = nil,
    page: Int? = nil,
    size: Int? = nil
  ) {
    self.category = category
    self.page = page
    self.size = size
  }
}
