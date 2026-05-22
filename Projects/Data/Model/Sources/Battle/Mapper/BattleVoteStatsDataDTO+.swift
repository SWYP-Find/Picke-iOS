//
//  BattleVoteStatsDataDTO+.swift
//  Model
//

import Entity
import Foundation

public extension BattleVoteStatsDataDTO {
  func toDomain() -> BattleVoteStats {
    BattleVoteStats(
      options: options.map { $0.toDomain() },
      totalCount: totalCount,
      updatedAt: updatedAt.flatMap(Self.parseISO8601)
    )
  }

  /// `2026-05-22T13:28:16.697Z` 형태의 ISO8601 (fractional seconds 포함) 파싱.
  private static func parseISO8601(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value)
  }
}

public extension BattleVoteStatsOptionDTO {
  func toDomain() -> BattleVoteStatsOption {
    BattleVoteStatsOption(
      optionId: optionId,
      label: label,
      title: title ?? "",
      isCorrect: isCorrect ?? false,
      voteCount: voteCount,
      ratio: ratio > 1 ? ratio / 100.0 : ratio,
      stance: stance ?? "",
      imageUrl: imageUrl
    )
  }
}
