//
//  SearchBattleDataDTO+.swift
//  SearchDomain
//
//  Created by Picke on 10/11/26.
//

import Foundation
import HomeDomainInterface

public extension SearchBattlePageDataDTO {
  func toDomain() -> ExploreItemPage {
    ExploreItemPage(
      items: items.map { $0.toDomain() },
      nextOffset: nextOffset,
      hasNext: hasNext
    )
  }
}

public extension SearchBattleDTO {
  func toDomain() -> ExploreItem {
    ExploreItem(
      id: battleId,
      category: tags?.first?.name ?? "",
      title: title ?? "",
      summary: summary ?? "",
      minutes: Self.toMinutes(audioDuration ?? 0),
      viewCount: viewCount ?? 0,
      imageURL: thumbnailUrl
    )
  }

  /// Android `audioDuration / 60` — 초를 분으로 내림한다(60초 미만은 0분).
  private static func toMinutes(_ seconds: Int) -> Int {
    max(0, seconds) / 60
  }
}
