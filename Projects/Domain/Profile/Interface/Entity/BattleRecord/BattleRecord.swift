//
//  BattleRecord.swift
//  Entity
//

import Foundation

public struct BattleRecord: Equatable, Identifiable {
  public let battleId: String
  public let recordId: String
  public let voteSide: BattleVoteSide
  public let category: String
  public let title: String
  public let summary: String
  public let createdAt: Date?

  public var id: String { recordId }

  /// 카테고리 태그 표시 (예: `#철학`).
  public var categoryTag: String {
    category.isEmpty ? "" : "#\(category)"
  }

  public init(
    battleId: String,
    recordId: String,
    voteSide: BattleVoteSide,
    category: String,
    title: String,
    summary: String,
    createdAt: Date?
  ) {
    self.battleId = battleId
    self.recordId = recordId
    self.voteSide = voteSide
    self.category = category
    self.title = title
    self.summary = summary
    self.createdAt = createdAt
  }
}
