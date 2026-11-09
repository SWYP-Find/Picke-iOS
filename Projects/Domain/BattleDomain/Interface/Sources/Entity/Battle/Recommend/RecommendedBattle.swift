//
//  RecommendedBattle.swift
//  BattleDomainInterface
//
//  Created by Picke on 10/11/26.
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

public extension RecommendedBattle {
  /// Android `RecommendItemCard` 태그 칩 — 첫 태그, 없으면 "#이슈".
  var tagLabel: String { "#\(tags.first?.name ?? "이슈")" }

  /// Android `RecommendUiModel.audioDuration` — 1~59초는 1분, 그 밖은 초 ÷ 60 내림.
  var durationLabel: String {
    let minutes = (1 ..< 60).contains(audioDuration) ? 1 : audioDuration / 60
    return "\(minutes)분"
  }
}
