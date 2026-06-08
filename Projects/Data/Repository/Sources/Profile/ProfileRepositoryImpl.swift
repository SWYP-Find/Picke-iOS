//
//  ProfileRepositoryImpl.swift
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

public final class ProfileRepositoryImpl: ProfileInterface, @unchecked Sendable {
  private let provider: MoyaProvider<ProfileService>

  public init(
    provider: MoyaProvider<ProfileService> = MoyaProvider<ProfileService>.authorized
  ) {
    self.provider = provider
  }

  public func fetchMyPage() async throws -> MyPage {
    let dto: MyPageResponseDTO = try await provider.request(.mypage)

    guard let data = dto.data else {
      let message = dto.error?.message ?? "마이페이지 응답이 비어 있습니다"
      Log.error("[ProfileRepositoryImpl] empty myPage payload: \(message)")
      throw ProfileError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchCreditHistory(
    offset: Int,
    size: Int
  ) async throws -> CreditHistoryPage {
    let dto: CreditHistoryResponseDTO = try await provider.request(
      .creditsHistory(query: CreditHistoryQueryRequest(offset: offset, size: size))
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "크레딧 내역 응답이 비어 있습니다"
      Log.error("[ProfileRepositoryImpl] empty creditHistory payload: \(message)")
      throw ProfileError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchBattleRecords(
    offset: Int,
    size: Int,
    voteSide: BattleVoteSide?
  ) async throws -> BattleRecordPage {
    let dto: BattleRecordResponseDTO = try await provider.request(
      .battleRecords(
        query: BattleRecordsQueryRequest(
          offset: offset,
          size: size,
          voteSide: voteSide.flatMap { $0 == .unknown ? nil : $0.rawValue }
        )
      )
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "배틀 기록 응답이 비어 있습니다"
      Log.error("[ProfileRepositoryImpl] empty battleRecords payload: \(message)")
      throw ProfileError.backendError(message)
    }

    return data.toDomain()
  }
}
