//
//  ProfileRepositoryImpl.swift
//  Repository
//

import Foundation

import Dependencies

import APIEndpoint
import PickeNetwork
import ProfileDomainInterface

public final class ProfileRepositoryImpl: ProfileInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchMyPage() async throws -> MyPage {
    let data = try await client.send(
      ProfileService.mypage,
      as: MyPageDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchRecap() async throws -> PhilosopherRecap {
    // 배틀 5개 미만 사용자는 서버가 data: nil (200) 로 응답 → 잠금 상태.
    // 에러로 던지지 않고 빈 recap(totalParticipation 0 → isLocked)으로 반환.
    do {
      let data = try await client.send(
        ProfileService.recap,
        as: RecapDataDTO.self
      )
      return data.toDomain()
    } catch PickeNetworkError.decoding(.dataMissing) {
      return .empty
    } catch {
      throw error
    }
  }

  public func fetchCreditHistory(
    offset: Int?,
    size: Int
  ) async throws -> CreditHistoryPage {
    let data = try await client.send(
      ProfileService.creditsHistory(
        query: CreditHistoryQueryRequest(
          offset: offset,
          size: size
        )
      ),
      as: CreditHistoryDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchBattleRecords(
    offset: Int,
    size: Int,
    voteSide: BattleVoteSide?
  ) async throws -> BattleRecordPage {
    let data = try await client.send(
      ProfileService.battleRecords(
        query: BattleRecordsQueryRequest(
          offset: offset,
          size: size,
          voteSide: voteSide.flatMap { $0 == .unknown ? nil : $0.rawValue }
        )
      ),
      as: BattleRecordDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchContentActivities(
    offset: Int,
    size: Int,
    activityType: ContentActivityType?
  ) async throws -> ContentActivityPage {
    let data = try await client.send(
      ProfileService.contentActivities(
        query: ContentActivitiesQueryRequest(
          offset: offset,
          size: size,
          activityType: activityType.flatMap(\.rawValue)
        )
      ),
      as: ContentActivityDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchNotificationSettings() async throws -> NotificationSettings {
    let data = try await client.send(
      ProfileService.notificationSettings,
      as: NotificationSettingsDataDTO.self
    )

    return data.toDomain()
  }

  public func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings {
    let data = try await client.send(
      ProfileService.updateNotificationSettings(
        body: NotificationSettingsRequest(
          newBattleEnabled: settings.newBattleEnabled,
          battleResultEnabled: settings.battleResultEnabled,
          commentReplyEnabled: settings.commentReplyEnabled,
          newCommentEnabled: settings.newCommentEnabled,
          contentLikeEnabled: settings.contentLikeEnabled,
          marketingEventEnabled: settings.marketingEventEnabled
        )
      ),
      as: NotificationSettingsDataDTO.self
    )

    return data.toDomain()
  }

  public func updateProfile(
    nickname: String,
    characterType: String
  ) async throws -> UpdatedProfile {
    let data = try await client.send(
      ProfileService.updateProfile(
        body: ProfileUpdateRequest(
          nickname: nickname,
          characterType: characterType
        )
      ),
      as: ProfileUpdateDataDTO.self
    )

    return data.toDomain()
  }
}
