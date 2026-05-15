//
//  HotBattle.swift
//  Entity
//
//  Created by Wonji Suh  on 5/15/26.
//

import Foundation

/// "지금 뜨는 배틀" 가로 스크롤 카드 — API 의 trendingBattles.
public struct HotBattle: Equatable, Identifiable {
  public let battleId: Int
  public let thumbnailURL: URL?
  public let title: String
  public let tags: [BattleTag]
  public let audioDuration: Int
  public let viewCount: Int

  public var id: Int { battleId }

  public init(
    battleId: Int,
    thumbnailURL: URL? = nil,
    title: String,
    tags: [BattleTag] = [],
    audioDuration: Int,
    viewCount: Int
  ) {
    self.battleId = battleId
    self.thumbnailURL = thumbnailURL
    self.title = title
    self.tags = tags
    self.audioDuration = audioDuration
    self.viewCount = viewCount
  }

  public var durationMinutes: Int { max(1, audioDuration / 60) }
}

public extension HotBattle {
  static let mocks: [HotBattle] = [
    .init(
      battleId: 11,
      title: "인간은 본래 선한가, 악한가?",
      tags: [.init(tagId: 301, name: "#철학", type: .category)],
      audioDuration: 8 * 60,
      viewCount: 1340
    ),
    .init(
      battleId: 12,
      title: "안락사 도입, 당신의 입장은?",
      tags: [.init(tagId: 302, name: "#역사", type: .category)],
      audioDuration: 5 * 60,
      viewCount: 1132
    ),
    .init(
      battleId: 13,
      title: "노키즈존, 영업의 자유인가?",
      tags: [.init(tagId: 303, name: "#사회", type: .category)],
      audioDuration: 5 * 60,
      viewCount: 902
    ),
    .init(
      battleId: 14,
      title: "AI는 의식을 가질 수 있는가?",
      tags: [.init(tagId: 304, name: "#과학", type: .category)],
      audioDuration: 6 * 60,
      viewCount: 780
    ),
  ]
}
