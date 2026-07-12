//
//  BattleRecordDataDTO+.swift
//  Model
//

import ProfileDomainInterface
import Foundation

public extension BattleRecordDataDTO {
  func toDomain() -> BattleRecordPage {
    BattleRecordPage(
      items: (items ?? []).map { $0.toDomain() },
      nextOffset: nextOffset ?? 0,
      hasNext: hasNext ?? false
    )
  }
}

public extension BattleRecordItemDTO {
  func toDomain() -> BattleRecord {
    BattleRecord(
      battleId: battleId ?? "",
      recordId: recordId ?? "",
      voteSide: BattleVoteSide(rawValue: voteSide ?? ""),
      category: category ?? "",
      title: title ?? "",
      summary: summary ?? "",
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
