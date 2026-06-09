//
//  RecapScores.swift
//  Entity
//
//  성향 분석 6축 점수 (0~100).
//

import Foundation

public struct RecapScores: Equatable {
  public let principle: Double
  public let reason: Double
  public let individual: Double
  public let change: Double
  public let inner: Double
  public let ideal: Double

  public init(
    principle: Double,
    reason: Double,
    individual: Double,
    change: Double,
    inner: Double,
    ideal: Double
  ) {
    self.principle = principle
    self.reason = reason
    self.individual = individual
    self.change = change
    self.inner = inner
    self.ideal = ideal
  }

  /// 레이더/바 표시 순서 (라벨, 0~100 값).
  public var axes: [RecapScoreAxis] {
    [
      RecapScoreAxis(label: "원칙", value: principle),
      RecapScoreAxis(label: "이성", value: reason),
      RecapScoreAxis(label: "개인", value: individual),
      RecapScoreAxis(label: "변화", value: change),
      RecapScoreAxis(label: "이상", value: ideal),
      RecapScoreAxis(label: "내면", value: inner),
    ]
  }
}
