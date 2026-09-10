//
//  BestBattle.swift
//  Entity
//
//  Created by Wonji Suh  on 5/15/26.
//

import Foundation

/// "Best 배틀" 랭킹 카드 — API 의 bestBattles.
public struct BestBattle: Equatable, Identifiable {
  public let battleId: Int
  public let rank: Int
  public let philosopherA: String
  public let philosopherB: String
  public let title: String
  public let tags: [BattleTag]
  public let audioDuration: Int
  public let viewCount: Int

  public var id: Int { battleId }

  public init(
    battleId: Int,
    rank: Int,
    philosopherA: String,
    philosopherB: String,
    title: String,
    tags: [BattleTag] = [],
    audioDuration: Int,
    viewCount: Int
  ) {
    self.battleId = battleId
    self.rank = rank
    self.philosopherA = philosopherA
    self.philosopherB = philosopherB
    self.title = title
    self.tags = tags
    self.audioDuration = audioDuration
    self.viewCount = viewCount
  }

  public var pair: String { "\(philosopherA) VS \(philosopherB)" }
  public var durationMinutes: Int { max(1, audioDuration / 60) }
}

public extension BestBattle {
  static let mocks: [BestBattle] = [
    .init(
      battleId: 21, rank: 1,
      philosopherA: "맹자", philosopherB: "순자",
      title: "인간은 본래 선한가, 악한가?",
      tags: [
        .init(tagId: 401, name: "#철학", type: .category),
        .init(tagId: 402, name: "#인문", type: .category),
      ],
      audioDuration: 8 * 60, viewCount: 1340
    ),
    .init(
      battleId: 22, rank: 2,
      philosopherA: "칸트", philosopherB: "톨스토이",
      title: "죽음을 앞둔 사람에게 진실을 말해야 하는가?",
      tags: [
        .init(tagId: 403, name: "#철학", type: .category),
        .init(tagId: 404, name: "#인문", type: .category),
      ],
      audioDuration: 8 * 60, viewCount: 1340
    ),
    .init(
      battleId: 23, rank: 3,
      philosopherA: "튜링", philosopherB: "설",
      title: "AI와 사랑에 빠지는 것, 진짜 사랑인가?",
      tags: [
        .init(tagId: 405, name: "#철학", type: .category),
        .init(tagId: 406, name: "#인문", type: .category),
      ],
      audioDuration: 8 * 60, viewCount: 1340
    ),
  ]
}
