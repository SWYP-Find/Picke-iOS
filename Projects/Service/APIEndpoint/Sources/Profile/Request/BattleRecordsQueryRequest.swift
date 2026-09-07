//
//  BattleRecordsQueryRequest.swift
//  Service
//

import Foundation

public struct BattleRecordsQueryRequest: Encodable, Sendable {
  public let offset: Int?
  public let size: Int?
  /// 투표 진영 필터 (PRO / CON). nil 이면 전체.
  public let voteSide: String?

  enum CodingKeys: String, CodingKey {
    case offset
    case size
    case voteSide = "vote_side"
  }

  public init(
    offset: Int? = nil,
    size: Int? = nil,
    voteSide: String? = nil
  ) {
    self.offset = offset
    self.size = size
    self.voteSide = voteSide
  }
}
