//
//  TodayBattleDataDTO+.swift
//  Model
//

import Entity
import Foundation

public extension TodayBattlePageDataDTO {
  func toDomain() -> TodayBattlePage {
    TodayBattlePage(
      items: items.map { $0.toDomain() },
      totalCount: totalCount
    )
  }
}
