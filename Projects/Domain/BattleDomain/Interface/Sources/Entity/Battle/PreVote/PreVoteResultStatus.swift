//
//  PreVoteResultStatus.swift
//  Entity
//

import Foundation

public enum PreVoteResultStatus: String, Equatable, Hashable, CaseIterable {
  case none = "NONE"
  case created = "CREATED"
  case updated = "UPDATED"
  case unknown

  public init(rawValue: String) {
    self = PreVoteResultStatus.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
