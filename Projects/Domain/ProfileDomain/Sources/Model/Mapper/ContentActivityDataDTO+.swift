//
//  ContentActivityDataDTO+.swift
//  ProfileDomain
//

import ProfileDomainInterface
import Foundation

public extension ContentActivityDataDTO {
  func toDomain() -> ContentActivityPage {
    ContentActivityPage(
      items: (items ?? []).map { $0.toDomain() },
      nextOffset: nextOffset ?? 0,
      hasNext: hasNext ?? false
    )
  }
}

public extension ContentActivityItemDTO {
  func toDomain() -> ContentActivity {
    ContentActivity(
      activityId: activityId ?? "",
      activityType: ContentActivityType(rawValue: activityType ?? ""),
      perspectiveId: perspectiveId ?? "",
      battleId: battleId ?? "",
      battleTitle: battleTitle ?? "",
      author: author?.toDomain() ?? ContentActivityAuthor(
        userTag: "",
        nickname: "",
        characterType: "",
        characterImageURL: ""
      ),
      voteSide: BattleVoteSide(rawValue: voteSide ?? ""),
      content: content ?? "",
      likeCount: likeCount ?? 0,
      createdAt: createdAt.flatMap(Self.parseISO8601)
    )
  }

  private static func parseISO8601(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value)
  }
}

public extension ContentActivityAuthorDTO {
  func toDomain() -> ContentActivityAuthor {
    ContentActivityAuthor(
      userTag: userTag ?? "",
      nickname: nickname ?? "",
      characterType: characterType ?? "",
      characterImageURL: characterImageUrl ?? ""
    )
  }
}
