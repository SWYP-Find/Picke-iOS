//
//  PollRepositoryImpl.swift
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

public final class PollRepositoryImpl: PollInterface, @unchecked Sendable {
  private let provider: MoyaProvider<PollService>

  public init(
    provider: MoyaProvider<PollService> = MoyaProvider<PollService>.authorized
  ) {
    self.provider = provider
  }

  public func fetchPoll(pollId: Int) async throws -> PollDetail {
    let dto: PollResponseDTO = try await provider.request(.detailPoll(pollId: pollId))

    guard let data = dto.data else {
      let message = dto.error?.message ?? "투표 데이터 응답이 비어 있습니다"
      Log.error("[PollRepositoryImpl] empty poll payload: \(message)")
      throw AuthError.backendError(message)
    }

    return data.toDomain()
  }
}
