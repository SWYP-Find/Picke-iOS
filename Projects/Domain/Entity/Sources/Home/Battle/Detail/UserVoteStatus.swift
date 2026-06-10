//
//  UserVoteStatus.swift
//  Entity
//

import Foundation

public enum UserVoteStatus: String, Equatable, Hashable, CaseIterable {
  case none = "NONE"
  case pro = "PRO"
  case con = "CON"
  case unknown

  public init(rawValue: String) {
    self = UserVoteStatus.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
