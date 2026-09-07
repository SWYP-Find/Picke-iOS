//
//  RecommendedBattle.swift
//  Entity
//

import Foundation

public struct RecommendedBattle: Equatable, Identifiable, Hashable {
  public let battleId: Int
  public let title: String
  public let summary: String
  public let audioDuration: Int
  public let viewCount: Int
  public let tags: [RecommendedBattleTag]
  public let participantsCount: Int
  public let options: [RecommendedBattleOption]

  public var id: Int { battleId }

  public init(
    battleId: Int,
    title: String,
    summary: String,
    audioDuration: Int,
    viewCount: Int,
    tags: [RecommendedBattleTag],
    participantsCount: Int,
    options: [RecommendedBattleOption]
  ) {
    self.battleId = battleId
    self.title = title
    self.summary = summary
    self.audioDuration = audioDuration
    self.viewCount = viewCount
    self.tags = tags
    self.participantsCount = participantsCount
    self.options = options
  }
}
