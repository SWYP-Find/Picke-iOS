//
//  PerspectiveDetailDataDTO+.swift
//  PerspectiveDomain
//

import Foundation

import BattleDomainInterface
import PickeCoreUtility

public extension PerspectiveDetailDataDTO {
  func toDomain() -> BattlePerspective {
    BattlePerspective(
      perspectiveId: perspectiveId,
      user: user.toDomain(),
      option: option.toDomain(),
      content: content,
      likeCount: likeCount,
      commentCount: commentCount,
      isLiked: isLiked ?? false,
      isMyPerspective: isMyPerspective ?? false,
      createdAt: createdAt.flatMap(ServerDateParser.parse)
    )
  }
}

public extension PerspectiveDetailUserDTO {
  func toDomain() -> BattlePerspectiveUser {
    BattlePerspectiveUser(
      userTag: userTag ?? "",
      nickname: nickname ?? "익명",
      characterType: characterType ?? "",
      characterImageUrl: characterImageUrl
    )
  }
}

public extension PerspectiveDetailOptionDTO {
  func toDomain() -> BattlePerspectiveOption {
    BattlePerspectiveOption(
      optionId: optionId,
      label: label,
      title: title ?? "",
      stance: stance ?? ""
    )
  }
}
