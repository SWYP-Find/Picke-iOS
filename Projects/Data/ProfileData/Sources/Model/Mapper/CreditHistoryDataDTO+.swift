//
//  CreditHistoryDataDTO+.swift
//  Model
//

import Foundation
import Model
import ProfileDomainInterface

public extension CreditHistoryDataDTO {
  func toDomain() -> CreditHistoryPage {
    CreditHistoryPage(
      items: (items ?? []).map { $0.toDomain() },
      nextOffset: nextOffset ?? 0,
      hasNext: hasNext ?? false
    )
  }
}

public extension CreditHistoryItemDTO {
  func toDomain() -> CreditHistoryItem {
    CreditHistoryItem(
      id: id ?? 0,
      creditType: creditType ?? "",
      amount: amount ?? 0,
      referenceId: referenceId,
      createdAt: createdAt.flatMap(Self.parseISO8601)
    )
  }

  private static func parseISO8601(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    if let date = formatter.date(from: value) { return date }
    // 타임존 없이 내려오는 서버 시각(예: "2026-07-12T21:26:26.921763") — KST 벽시계로 해석.
    return ServerNaiveDateParser.date(from: value)
  }
}
