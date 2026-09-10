//
//  TodayBattlePage.swift
//  Entity
//

import Foundation

public struct TodayBattlePage: Equatable {
  public let items: [BattleInfo]
  public let totalCount: Int

  public init(
    items: [BattleInfo],
    totalCount: Int
  ) {
    self.items = items
    self.totalCount = totalCount
  }
}
