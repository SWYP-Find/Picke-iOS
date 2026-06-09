//
//  RecapScoreAxis.swift
//  Entity
//

import Foundation

public struct RecapScoreAxis: Equatable, Identifiable {
  public let label: String
  /// 0~100.
  public let value: Double

  public var id: String { label }

  public init(label: String, value: Double) {
    self.label = label
    self.value = value
  }
}
