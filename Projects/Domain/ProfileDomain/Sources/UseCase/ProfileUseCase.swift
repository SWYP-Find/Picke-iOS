//
//  ProfileUseCase.swift
//  UseCase
//

import Foundation

import ProfileDomainInterface

import ComposableArchitecture

public struct ProfileUseCaseImpl: ProfileInterface {
  @Dependency(\.profileRepository) private var profileRepository

  public init() {}

  public func fetchMyPage() async throws -> MyPage {
    return try await profileRepository.fetchMyPage()
  }

  public func fetchRecap() async throws -> PhilosopherRecap {
    return try await profileRepository.fetchRecap()
  }

  public func fetchCreditHistory(
    offset: Int?,
    size: Int
  ) async throws -> CreditHistoryPage {
    return try await profileRepository.fetchCreditHistory(offset: offset, size: size)
  }

  public func fetchBattleRecords(
    offset: Int,
    size: Int,
    voteSide: BattleVoteSide?
  ) async throws -> BattleRecordPage {
    return try await profileRepository.fetchBattleRecords(
      offset: offset,
      size: size,
      voteSide: voteSide
    )
  }

  public func fetchContentActivities(
    offset: Int,
    size: Int,
    activityType: ContentActivityType?
  ) async throws -> ContentActivityPage {
    return try await profileRepository.fetchContentActivities(
      offset: offset,
      size: size,
      activityType: activityType
    )
  }

  public func fetchNotificationSettings() async throws -> NotificationSettings {
    return try await profileRepository.fetchNotificationSettings()
  }

  public func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings {
    return try await profileRepository.updateNotificationSettings(settings)
  }

  public func updateProfile(
    nickname: String,
    characterType: String
  ) async throws -> UpdatedProfile {
    return try await profileRepository.updateProfile(
      nickname: nickname,
      characterType: characterType
    )
  }
}
