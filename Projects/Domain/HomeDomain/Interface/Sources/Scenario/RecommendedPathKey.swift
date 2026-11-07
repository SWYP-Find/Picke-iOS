//
//  RecommendedPathKey.swift
//  HomeDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum RecommendedPathKey: String, Equatable, Hashable, CaseIterable {
  case common = "COMMON"
  case pathA = "PATH_A"
  case pathB = "PATH_B"
  case unknown

  public init(rawValue: String) {
    self = RecommendedPathKey.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
