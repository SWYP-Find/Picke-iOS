//
//  RecommendedPathKey.swift
//  Entity
//

import Foundation

public enum RecommendedPathKey: String, Equatable, Hashable, CaseIterable {
  case common = "COMMON"
  case unknown

  public init(rawValue: String) {
    self = RecommendedPathKey.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
