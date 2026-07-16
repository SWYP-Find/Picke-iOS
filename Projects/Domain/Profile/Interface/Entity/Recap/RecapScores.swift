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

  public static let empty = RecapScores(
    principle: 0, reason: 0, individual: 0, change: 0, inner: 0, ideal: 0
  )

  /// 레이더 각도 순서 (원칙↑ → 시계방향: 이성·개인·변화·내면·이상).
  public var axes: [RecapScoreAxis] {
    [
      RecapScoreAxis(label: "원칙", value: principle),
      RecapScoreAxis(label: "이성", value: reason),
      RecapScoreAxis(label: "개인", value: individual),
      RecapScoreAxis(label: "변화", value: change),
      RecapScoreAxis(label: "내면", value: inner),
      RecapScoreAxis(label: "이상", value: ideal),
    ]
  }

  /// 점수 바 2열 그리드 순서 (picke.pen: 원칙·이성 / 개인·변화 / 내면·이상).
  public var gridAxes: [RecapScoreAxis] {
    [
      RecapScoreAxis(label: "원칙", value: principle),
      RecapScoreAxis(label: "이성", value: reason),
      RecapScoreAxis(label: "개인", value: individual),
      RecapScoreAxis(label: "변화", value: change),
      RecapScoreAxis(label: "내면", value: inner),
      RecapScoreAxis(label: "이상", value: ideal),
    ]
  }
}
