//
//  TodayBattlePage.swift
//  Entity
//
//  `GET /api/v1/battles/today` 응답 도메인 모델. 아이템은 BattleInfo 재사용.
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
