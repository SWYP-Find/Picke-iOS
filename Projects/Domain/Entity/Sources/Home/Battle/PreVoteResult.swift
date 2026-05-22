//
//  PreVoteResult.swift
//  Entity
//

import Foundation

public struct PreVoteResult: Equatable, Hashable {
  public let voteId: Int
  public let status: PreVoteResultStatus

  public init(
    voteId: Int,
    status: PreVoteResultStatus
  ) {
    self.voteId = voteId
    self.status = status
  }
}

public enum PreVoteResultStatus: String, Equatable, Hashable, CaseIterable {
  case none = "NONE"
  case created = "CREATED"
  case updated = "UPDATED"
  case unknown

  public init(rawValue: String) {
    self = PreVoteResultStatus.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
