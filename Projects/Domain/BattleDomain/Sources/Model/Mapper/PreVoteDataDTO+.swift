//
//  PreVoteDataDTO+.swift
//  BattleDomain
//
//  Created by Picke on 10/11/26.
//

import BattleDomainInterface
import Foundation

public extension PreVoteDataDTO {
  func toDomain() -> PreVoteResult {
    PreVoteResult(
      voteId: voteId,
      status: PreVoteResultStatus(rawValue: status)
    )
  }
}
