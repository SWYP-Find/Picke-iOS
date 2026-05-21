//
//  BattleDetailDataDTO+.swift
//  Model
//

import Entity
import Foundation

public extension BattleDetailDataDTO {
  func toDomain() -> BattleDetail {
    BattleDetail(
      battleInfo: battleInfo.toDomain(),
      description: description,
      shareUrl: shareUrl,
      userVoteStatus: userVoteStatus.map { UserVoteStatus(rawValue: $0) } ?? .none,
      currentStep: currentStep.map { BattleStep(rawValue: $0) } ?? .none,
      categoryTags: categoryTags.map { $0.toDomain() },
      philosopherTags: philosopherTags.map { $0.toDomain() },
      valueTags: valueTags.map { $0.toDomain() }
    )
  }
}

public extension BattleInfoDTO {
  func toDomain() -> BattleInfo {
    BattleInfo(
      battleId: battleId,
      title: title,
      summary: summary,
      thumbnailUrl: thumbnailUrl,
      viewCount: viewCount,
      participantsCount: participantsCount,
      audioDuration: audioDuration,
      tags: tags.map { $0.toDomain() },
      options: options.map { $0.toDomain() }
    )
  }
}

public extension BattleOptionDTO {
  func toDomain() -> BattleOption {
    BattleOption(
      optionId: optionId,
      label: label,
      title: title,
      stance: stance,
      representative: representative,
      imageUrl: imageUrl,
      tags: tags.map { $0.toDomain() }
    )
  }
}

public extension BattleTagDTO {
  func toDomain() -> BattleTag {
    BattleTag(
      tagId: tagId,
      name: name,
      type: TagType(rawValue: type)
    )
  }
}
