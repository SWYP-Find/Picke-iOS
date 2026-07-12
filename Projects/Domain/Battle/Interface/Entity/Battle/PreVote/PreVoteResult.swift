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
