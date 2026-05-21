//
//  DefaultBattleRepositoryImpl.swift
//  DomainInterface
//

import Entity
import Foundation

public struct DefaultBattleRepositoryImpl: BattleInterface {
  public init() {}

  public func fetchBattle(battleId _: Int) async throws -> BattleDetail {
    BattleDetail(
      battleInfo: BattleInfo(
        battleId: 0,
        title: "",
        summary: "",
        thumbnailUrl: "",
        viewCount: 0,
        participantsCount: 0,
        audioDuration: 0,
        tags: [],
        options: []
      ),
      description: "",
      shareUrl: "",
      userVoteStatus: .none,
      currentStep: .none,
      categoryTags: [],
      philosopherTags: [],
      valueTags: []
    )
  }

  public func submitPostVote(battleId _: Int, optionId _: Int) async throws -> PreVoteResult {
    PreVoteResult(voteId: 0, status: .none)
  }

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
