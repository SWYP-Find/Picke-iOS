//
//  TodayBattleDataDTO+.swift
//  BattleDomain
//

import BattleDomainInterface
import Foundation

public extension TodayBattlePageDataDTO {
  func toDomain() -> TodayBattlePage {
    TodayBattlePage(
      items: items.map { $0.toDomain() },
      totalCount: totalCount
    )
  }
}
