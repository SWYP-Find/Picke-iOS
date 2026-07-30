//
//  BattlePerspectiveDataDTO+.swift
//  Model
//

import CommonDomainInterface
import Foundation

public extension BattlePerspectivePageDataDTO {
  func toDomain() -> BattlePerspectivePage {
    BattlePerspectivePage(
      items: items.map { $0.toDomain() },
      nextCursor: nextCursor,
      hasNext: hasNext
    )
  }
}

public extension BattlePerspectiveDTO {
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
      createdAt: createdAt.flatMap(Self.parseISO8601)
    )
  }

  private static func parseISO8601(_ value: String) -> Date? {
    PerspectiveDateParser.parse(value)
  }
}

public extension BattlePerspectiveUserDTO {
  func toDomain() -> BattlePerspectiveUser {
    BattlePerspectiveUser(
      userTag: userTag ?? "",
      nickname: nickname ?? "익명",
      characterType: characterType ?? "",
      characterImageUrl: characterImageUrl
    )
  }
}

public extension BattlePerspectiveOptionDTO {
  func toDomain() -> BattlePerspectiveOption {
    BattlePerspectiveOption(
      optionId: optionId,
      label: label,
      title: title ?? "",
      stance: stance ?? ""
    )
  }
}
