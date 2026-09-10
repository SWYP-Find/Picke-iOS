//
//  SearchBattleDataDTO+.swift
//  SearchDomain
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

  /// 초 단위 오디오 길이를 분으로 환산 (최소 1분).
  private static func toMinutes(_ seconds: Int) -> Int {
    guard seconds > 0 else { return 0 }
    return max(1, Int((Double(seconds) / 60).rounded()))
  }
}
