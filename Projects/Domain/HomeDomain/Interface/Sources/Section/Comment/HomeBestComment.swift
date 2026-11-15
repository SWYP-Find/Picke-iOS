//
//  HomeBestComment.swift
//  HomeDomainInterface
//

import Foundation

/// 홈 Best 댓글 — `GET /api/v1/perspectives/weekly-best` 항목 (Android `HomeBestCommentUiModel`).
public struct HomeBestComment: Equatable, Identifiable {
  public let perspectiveId: Int
  public let battleId: Int
  public let battleTitle: String
  public let content: String

  public var id: Int {
    perspectiveId
  }

  public init(
    perspectiveId: Int,
    battleId: Int,
    battleTitle: String,
    content: String
  ) {
    self.perspectiveId = perspectiveId
    self.battleId = battleId
    self.battleTitle = battleTitle
    self.content = content
  }
}
