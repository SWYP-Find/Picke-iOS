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

  public func fetchScenario(battleId _: Int) async throws -> BattleScenario {
    BattleScenario(
      battleId: 0,
      title: "",
      philosophers: [],
      isInteractive: false,
      startNodeId: 0,
      recommendedPathKey: .common,
      audios: [:],
      nodes: []
    )
  }
}
