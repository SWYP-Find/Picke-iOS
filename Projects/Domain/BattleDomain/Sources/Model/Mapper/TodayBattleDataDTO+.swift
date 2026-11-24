//
//  TodayBattleDataDTO+.swift
//  BattleDomain
//
//  Created by Picke on 10/11/26.
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
