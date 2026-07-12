//
//  BattleVoteStats.swift
//  Entity
//
//  `GET /api/v1/battles/{battleId}/vote-stats` 응답 도메인 모델.
//  댓글 화면 상단의 옵션별 비율 막대 / 참여자 수 표시에 사용.
//

import Foundation

public struct BattleVoteStats: Equatable {
  public let options: [BattleVoteStatsOption]
  public let totalCount: Int
  public let updatedAt: Date?

  public init(
    options: [BattleVoteStatsOption],
    totalCount: Int,
    updatedAt: Date?
  ) {
    self.options = options
    self.totalCount = totalCount
    self.updatedAt = updatedAt
  }
}
