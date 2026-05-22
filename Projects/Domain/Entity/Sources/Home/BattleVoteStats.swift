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

public struct BattleVoteStatsOption: Equatable, Identifiable, Hashable {
  public let optionId: Int
  public let label: String?
  public let title: String
  public let isCorrect: Bool
  public let voteCount: Int
  public let ratio: Double
  public let stance: String

  public var id: Int { optionId }

  public init(
    optionId: Int,
    label: String?,
    title: String,
    isCorrect: Bool,
    voteCount: Int,
    ratio: Double,
    stance: String
  ) {
    self.optionId = optionId
    self.label = label
    self.title = title
    self.isCorrect = isCorrect
    self.voteCount = voteCount
    self.ratio = ratio
    self.stance = stance
  }
}
