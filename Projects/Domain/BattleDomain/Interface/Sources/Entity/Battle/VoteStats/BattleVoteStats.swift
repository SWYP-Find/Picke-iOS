//
//  BattleVoteStats.swift
//  Entity
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
