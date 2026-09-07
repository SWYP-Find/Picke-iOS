//
//  CreditHistoryDataDTO+.swift
//  ProfileDomain
//

import Foundation

import PickeCoreUtility
import PickeNetworkInterface
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
      createdAt: createdAt.flatMap(ServerDateParser.parse)
    )
  }
}
