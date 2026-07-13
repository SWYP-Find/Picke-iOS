//
//  ProfileRepositoryImpl.swift
//  Repository
//

import Foundation

import ProfileDomainInterface
import Repository

import LogMacro


public final class ProfileRepositoryImpl: ProfileInterface, @unchecked Sendable {
  private let provider: any NetworkProviding<ProfileService>

  public init(
    provider: any NetworkProviding<ProfileService> = AlamofireNetworkProvider<ProfileService>.authorized
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

  public func fetchRecap() async throws -> PhilosopherRecap {
    let dto: RecapResponseDTO = try await provider.request(.recap)

    // 배틀 5개 미만 사용자는 서버가 data: nil (200) 로 응답 → 잠금 상태.
    // 에러로 던지지 않고 빈 recap(totalParticipation 0 → isLocked)으로 반환.
    guard let data = dto.data else {
      Log.info("[ProfileRepositoryImpl] recap 빈 응답 → 잠금 화면 반환")
      return .empty
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

  public func fetchContentActivities(
    offset: Int,
    size: Int,
    activityType: ContentActivityType?
  ) async throws -> ContentActivityPage {
    let dto: ContentActivityResponseDTO = try await provider.request(
      .contentActivities(
        query: ContentActivitiesQueryRequest(
          offset: offset,
          size: size,
          activityType: activityType.flatMap(\.rawValue)
        )
      )
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "콘텐츠 활동 응답이 비어 있습니다"
      Log.error("[ProfileRepositoryImpl] empty contentActivities payload: \(message)")
      throw ProfileError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchNotificationSettings() async throws -> NotificationSettings {
    let dto: NotificationSettingsResponseDTO = try await provider.request(.notificationSettings)

    guard let data = dto.data else {
      let message = dto.error?.message ?? "알림 설정 응답이 비어 있습니다"
      Log.error("[ProfileRepositoryImpl] empty notificationSettings payload: \(message)")
      throw ProfileError.backendError(message)
    }

    return data.toDomain()
  }

  public func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings {
    let dto: NotificationSettingsResponseDTO = try await provider.request(
      .updateNotificationSettings(
        body: NotificationSettingsRequest(
          newBattleEnabled: settings.newBattleEnabled,
          battleResultEnabled: settings.battleResultEnabled,
          commentReplyEnabled: settings.commentReplyEnabled,
          newCommentEnabled: settings.newCommentEnabled,
          contentLikeEnabled: settings.contentLikeEnabled,
          marketingEventEnabled: settings.marketingEventEnabled
        )
      )
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "알림 설정 응답이 비어 있습니다"
      Log.error("[ProfileRepositoryImpl] empty updateNotificationSettings payload: \(message)")
      throw ProfileError.backendError(message)
    }

    return data.toDomain()
  }
}
