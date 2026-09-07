//
//  BattleRepositoryImpl.swift
//  Repository
//

import Foundation
import PickeCoreLogger

import Dependencies

import APIEndpoint
import BattleDomainInterface
import HomeDomainInterface
import PickeNetwork


public final class BattleRepositoryImpl: BattleInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchTodayBattles() async throws -> TodayBattlePage {
    let data = try await client.send(
      BattleService.today,
      as: TodayBattlePageDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchBattle(battleId: Int) async throws -> BattleDetail {
    let data = try await client.send(
      BattleService.detail(battleId: battleId),
      as: BattleDetailDataDTO.self
    )

    return data.toDomain()
  }

  public func submitPreVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    let data = try await client.send(
      BattleService.preVote(battleId: battleId, body: PreVoteRequest(optionId: optionId)),
      as: PreVoteDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchVoteStats(battleId: Int) async throws -> BattleVoteStats {
    let data = try await client.send(
      BattleService.voteStats(battleId: battleId),
      as: BattleVoteStatsDataDTO.self
    )

    return data.toDomain()
  }

  public func submitPostVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    let data = try await client.send(
      BattleService.postVote(battleId: battleId, body: PreVoteRequest(optionId: optionId)),
      as: PreVoteDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchPerspectives(
    battleId: Int,
    cursor: String?,
    size: Int?,
    optionId: Int?,
    sort: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage {
    let data = try await client.send(
      BattleService.perspectives(
        battleId: battleId,
        query: PerspectivesQueryRequest(cursor: cursor, size: size, optionId: optionId, sort: sort?.queryValue)
      ),
      as: BattlePerspectivePageDataDTO.self
    )

    return data.toDomain()
  }

  public func createPerspective(
    battleId: Int,
    content: String,
    optionId: Int?
  ) async throws -> BattlePerspective? {
    _ = try await client.send(
      BattleService.createPerspective(
        battleId: battleId,
        body: CreatePerspectiveRequest(content: content, optionId: optionId)
      ),
      as: CreatePerspectiveDataDTO.self
    )

    // 등록 응답에는 진영(option)이 없어 재조회로 채운다. 재조회가 실패해도 등록은 이미 성공했으므로
    // 실패로 뒤집지 않고 nil 을 돌려준다 — 호출부는 목록만 갱신하고 진영 전환을 건너뛴다.
    let perspective = try? await fetchMyPerspective(battleId: battleId)
    if perspective == nil {
      PickeLogger.error("[BattleRepositoryImpl] createPerspective 재조회 실패 — 등록은 성공", category: .battle)
    }
    return perspective
  }

  public func fetchMyPerspective(battleId: Int) async throws -> BattlePerspective? {
    let dto: BattlePerspectiveDTO
    do {
      dto = try await client.send(
        BattleService.myPerspective(battleId: battleId),
        as: BattlePerspectiveDTO.self
      )
    } catch {
      PickeLogger.debug("[BattleRepositoryImpl] fetchMyPerspective failed (no participation): \(error.localizedDescription)", category: .battle)
      return nil
    }

    return dto.toDomain()
  }

  public func fetchScenario(battleId: Int) async throws -> BattleScenario {
    let data = try await client.send(
      BattleService.scenario(battleId: battleId),
      as: BattleScenarioDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchRecommendedBattles(battleId: Int) async throws -> RecommendedBattlePage {
    let data = try await client.send(
      BattleService.recommendations(battleId: battleId),
      as: RecommendedBattlePageDataDTO.self
    )

    return data.toDomain()
  }

  public func proposeBattle(_ draft: BattleProposalDraft) async throws -> BattleProposal {
    let data = try await client.send(
      BattleService.createProposal(body: BattleProposalRequest(
        category: draft.category,
        topic: draft.topic,
        positionA: draft.positionA,
        positionB: draft.positionB,
        description: draft.description
      )),
      as: BattleProposalDataDTO.self
    )

    return data.toDomain()
  }
}
