//
//  MyTier.swift
//  Entity
//

import Foundation

public struct MyTier: Equatable {
  /// 티어 코드 (예: `WANDERER`).
  public let tierCode: String
  public let tierLabel: String
  /// 보유 포인트.
  public let currentPoint: Int

  public init(
    tierCode: String,
    tierLabel: String,
    currentPoint: Int
  ) {
    self.tierCode = tierCode
    self.tierLabel = tierLabel
    self.currentPoint = currentPoint
  }
}
