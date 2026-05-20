//
//  BattleRepositoryImpl.swift
//  Repository
//

import Foundation

import DomainInterface
import Entity
import Model
import Service

import LogMacro
import Moya

@preconcurrency import AsyncMoya

public final class BattleRepositoryImpl: BattleInterface, @unchecked Sendable {
  private let provider: MoyaProvider<BattleService>

  public init(
    provider: MoyaProvider<BattleService> = MoyaProvider<BattleService>.authorized
  ) {
    self.provider = provider
  }

  public func submitPreVote(battleId: Int, optionId: Int) async throws -> PreVoteResult {
    let dto: PreVoteResponseDTO = try await provider.request(
      .preVote(battleId: battleId, body: PreVoteRequest(optionId: optionId))
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "사전 투표 응답이 비어 있습니다"
      Log.error("[BattleRepositoryImpl] empty preVote payload: \(message)")
      throw AuthError.backendError(message)
    }

    return data.toDomain()
  }
}
