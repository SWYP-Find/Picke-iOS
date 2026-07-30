//
//  BattleProposalDataDTO+.swift
//  Model
//

import BattleDomainInterface
import Foundation

public extension BattleProposalDataDTO {
  func toDomain() -> BattleProposal {
    BattleProposal(
      id: id ?? 0,
      userId: userId ?? 0,
      nickname: nickname ?? "",
      category: category ?? "",
      topic: topic ?? "",
      positionA: positionA ?? "",
      positionB: positionB ?? "",
      description: description ?? "",
      status: status ?? "",
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
