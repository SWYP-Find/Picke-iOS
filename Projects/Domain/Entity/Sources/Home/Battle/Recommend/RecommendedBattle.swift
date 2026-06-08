//
//  RecommendedBattle.swift
//  Entity
//
//  `GET /api/v1/battles/{battleId}/recommendations/interesting` 응답 도메인 모델.
//  특정 배틀 기준 흥미로운 배틀 추천 목록 + 커서 페이지네이션.
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
