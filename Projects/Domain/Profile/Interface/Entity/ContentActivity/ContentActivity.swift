//
//  ContentActivity.swift
//  Entity
//
//  `GET /api/v1/me/content-activities` 항목 (내가 단/좋아요한 댓글).
//

import Foundation

public struct ContentActivity: Equatable, Identifiable {
  public let activityId: String
  public let activityType: ContentActivityType
  public let perspectiveId: String
  public let battleId: String
  public let battleTitle: String
  public let author: ContentActivityAuthor
  public let voteSide: BattleVoteSide
  public let content: String
  public let likeCount: Int
  public let createdAt: Date?

  public var id: String { activityId }

  /// 의견 칩 텍스트 (찬성의견 / 반대의견).
  public var stanceText: String {
    switch voteSide {
    case .pro: "찬성의견"
    case .con: "반대의견"
    case .unknown: ""
    }
  }

  public init(
    activityId: String,
    activityType: ContentActivityType,
    perspectiveId: String,
    battleId: String,
    battleTitle: String,
    author: ContentActivityAuthor,
    voteSide: BattleVoteSide,
    content: String,
    likeCount: Int,
    createdAt: Date?
  ) {
    self.activityId = activityId
    self.activityType = activityType
    self.perspectiveId = perspectiveId
    self.battleId = battleId
    self.battleTitle = battleTitle
    self.author = author
    self.voteSide = voteSide
    self.content = content
    self.likeCount = likeCount
    self.createdAt = createdAt
  }
}
