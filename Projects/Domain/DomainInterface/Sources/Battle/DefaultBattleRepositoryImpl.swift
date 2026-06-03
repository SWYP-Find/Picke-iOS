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

  public func submitPostVote(
    battleId _: Int,
    optionId _: Int
  ) async throws -> PreVoteResult {
    PreVoteResult(voteId: 0, status: .none)
  }

  public func fetchVoteStats(battleId _: Int) async throws -> BattleVoteStats {
    BattleVoteStats(options: [], totalCount: 0, updatedAt: nil)
  }

  public func fetchPerspectives(
    battleId _: Int,
    cursor _: String?,
    size _: Int?,
    optionId _: Int?,
    sort _: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage {
    BattlePerspectivePage(items: [], nextCursor: nil, hasNext: false)
  }

  public func submitPreVote(
    battleId _: Int,
    optionId _: Int
  ) async throws -> PreVoteResult {
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

  public func createPerspective(
    battleId _: Int,
    content: String,
    optionId: Int
  ) async throws -> BattlePerspective {
    BattlePerspective(
      perspectiveId: 0,
      user: BattlePerspectiveUser(userTag: "", nickname: "나", characterType: "", characterImageUrl: nil),
      option: BattlePerspectiveOption(optionId: optionId, label: nil, title: "", stance: ""),
      content: content,
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
      isMyPerspective: true,
      createdAt: Date()
    )
  }

  public func fetchMyPerspective(battleId _: Int) async throws -> BattlePerspective? {
    nil
  }
}
