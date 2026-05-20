//
//  DefaultBattleRepositoryImpl.swift
//  DomainInterface
//

import Entity
import Foundation

public struct DefaultBattleRepositoryImpl: BattleInterface {
  public init() {}

  public func submitPreVote(battleId _: Int, optionId _: Int) async throws -> PreVoteResult {
    PreVoteResult(voteId: 0, status: .none)
  }
}
