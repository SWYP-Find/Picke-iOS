//
//  ContentActivitiesQueryRequest.swift
//  Service
//
//  GET /api/v1/me/content-activities 쿼리 파라미터.
//

import Foundation

public struct ContentActivitiesQueryRequest: Encodable {
  public let offset: Int?
  public let size: Int?
  /// 활동 유형 필터 (COMMENT / LIKE). nil 이면 전체.
  public let activityType: String?

  enum CodingKeys: String, CodingKey {
    case offset
    case size
    case activityType = "activity_type"
  }

  public init(
    offset: Int? = nil,
    size: Int? = nil,
    activityType: String? = nil
  ) {
    self.offset = offset
    self.size = size
    self.activityType = activityType
  }
}
