//
//  CreditHistoryDataDTO+.swift
//  Model
//

import Entity
import Foundation

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
    return formatter.date(from: value)
  }
}
