//
//  PreVoteDataDTO+.swift
//  Model
//

import Entity
import Foundation

public extension PreVoteDataDTO {
  func toDomain() -> PreVoteResult {
    PreVoteResult(
      voteId: voteId,
      status: PreVoteResultStatus(rawValue: status)
    )
  }
}
