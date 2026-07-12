//
//  RecommendedBattleDataDTO+.swift
//  Model
//

import Entity
import BattleDomainInterface
import CommonDomainInterface
import Foundation

public extension RecommendedBattlePageDataDTO {
  func toDomain() -> RecommendedBattlePage {
    RecommendedBattlePage(
      items: items.map { $0.toDomain() },
      nextCursor: nextCursor,
      hasNext: hasNext
    )
  }
}

public extension RecommendedBattleDTO {
  func toDomain() -> RecommendedBattle {
    RecommendedBattle(
      battleId: battleId,
      title: title ?? "",
      summary: summary ?? "",
      audioDuration: audioDuration ?? 0,
      viewCount: viewCount ?? 0,
      tags: (tags ?? []).map { $0.toDomain() },
      participantsCount: participantsCount ?? 0,
      options: (options ?? []).map { $0.toDomain() }
    )
  }
}

public extension RecommendedBattleTagDTO {
  func toDomain() -> RecommendedBattleTag {
    RecommendedBattleTag(tagId: tagId, name: name ?? "")
  }
}

public extension RecommendedBattleOptionDTO {
  func toDomain() -> RecommendedBattleOption {
    RecommendedBattleOption(
      optionId: optionId,
      title: title ?? "",
      stance: stance ?? "",
      representative: representative ?? "",
      imageUrl: imageUrl
    )
  }
}
