//
//  BattleRepositoryImpl.swift
//  Repository
//

import Foundation

import BattleDomainInterface
import CommonDomainInterface
import DomainInterface
import Entity
import HomeDomainInterface
import Model
import Repository
import Service

import LogMacro

public final class BattleRepositoryImpl: BattleInterface, @unchecked Sendable {
  private let provider: any NetworkProviding<BattleService>

  public init(
    provider: any NetworkProviding<BattleService> = AlamofireNetworkProvider<BattleService>.authorized
  ) {
    self.provider = provider
  }

  public func fetchTodayBattles() async throws -> TodayBattlePage {
    let dto: TodayBattlePageResponseDTO = try await provider.request(.today)

    guard let data = dto.data else {
      let message = dto.error?.message ?? "오늘의 배틀 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty todayBattles payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchBattle(battleId: Int) async throws -> BattleDetail {
    let dto: BattleDetailResponseDTO = try await provider.request(
      .detail(battleId: battleId)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "배틀 상세 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty battleDetail payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }

  public func submitPreVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    let dto: PreVoteResponseDTO = try await provider.request(
      .preVote(battleId: battleId, body: PreVoteRequest(optionId: optionId))
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "사전 투표 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty preVote payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchVoteStats(battleId: Int) async throws -> BattleVoteStats {
    let dto: BattleVoteStatsResponseDTO = try await provider.request(
      .voteStats(battleId: battleId)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "투표 통계 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty voteStats payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }

  public func submitPostVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    let dto: PreVoteResponseDTO = try await provider.request(
      .postVote(battleId: battleId, body: PreVoteRequest(optionId: optionId))
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "최종 투표 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty postVote payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchPerspectives(
    battleId: Int,
    cursor: String?,
    size: Int?,
    optionId: Int?,
    sort: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage {
    let dto: BattlePerspectivePageResponseDTO = try await provider.request(
      .perspectives(
        battleId: battleId,
        query: PerspectivesQueryRequest(
          cursor: cursor,
          size: size,
          optionId: optionId,
          sort: sort?.queryValue
        )
      )
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "댓글 목록 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty perspectives payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }

  public func createPerspective(
    battleId: Int,
    content: String,
    optionId: Int?
  ) async throws -> BattlePerspective? {
    let dto: CreatePerspectiveResponseDTO = try await provider.request(
      .createPerspective(
        battleId: battleId,
        body: CreatePerspectiveRequest(content: content, optionId: optionId)
      )
    )

    guard dto.data != nil else {
      let message = dto.error?.message ?? "댓글 작성 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty createPerspective payload: \(message)")
      throw BattleError.backendError(message)
    }

    // 등록 응답에는 진영(option)이 없어 재조회로 채운다. 재조회가 실패해도 등록은 이미 성공했으므로
    // 실패로 뒤집지 않고 nil 을 돌려준다 — 호출부는 목록만 갱신하고 진영 전환을 건너뛴다.
    let perspective = try? await fetchMyPerspective(battleId: battleId)
    if perspective == nil {
      Log.error("[BattleRepositoryImpl] createPerspective 재조회 실패 — 등록은 성공")
    }
    return perspective
  }

  public func fetchMyPerspective(battleId: Int) async throws -> BattlePerspective? {
    let dto: BaseResponseDTO<BattlePerspectiveDTO>
    do {
      dto = try await provider.request(.myPerspective(battleId: battleId))
    } catch {
      Log.debug("[BattleRepositoryImpl] fetchMyPerspective failed (no participation): \(error.localizedDescription)")
      return nil
    }

    if dto.statusCode >= 400 {
      return nil
    }
    return dto.data?.toDomain()
  }

  public func fetchScenario(battleId: Int) async throws -> BattleScenario {
    let dto: BattleScenarioResponseDTO = try await provider.request(
      .scenario(battleId: battleId)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "시나리오 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty scenario payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchRecommendedBattles(battleId: Int) async throws -> RecommendedBattlePage {
    let dto: RecommendedBattlePageResponseDTO = try await provider.request(
      .recommendations(battleId: battleId)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "추천 배틀 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty recommendations payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }

  public func proposeBattle(_ draft: BattleProposalDraft) async throws -> BattleProposal {
    let dto: BattleProposalResponseDTO = try await provider.request(
      .createProposal(
        body: BattleProposalRequest(
          category: draft.category,
          topic: draft.topic,
          positionA: draft.positionA,
          positionB: draft.positionB,
          description: draft.description
        )
      )
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "배틀 제안 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty proposeBattle payload: \(message)")
      throw BattleError.backendError(message)
    }

    return data.toDomain()
  }
}
