//
//  ProfileUseCase.swift
//  UseCase
//

import Foundation

import DomainInterface
import Entity

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
    offset: Int,
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
}

extension ProfileUseCaseImpl: DependencyKey {
  public static var liveValue = ProfileUseCaseImpl()
  public static var testValue = ProfileUseCaseImpl()
  public static var previewValue = ProfileUseCaseImpl()
}

public extension DependencyValues {
  var profileUseCase: ProfileUseCaseImpl {
    get { self[ProfileUseCaseImpl.self] }
    set { self[ProfileUseCaseImpl.self] = newValue }
  }
}
