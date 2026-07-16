//
//  ProfileInterface.swift
//  DomainInterface
//

import Foundation
import WeaveDI

public protocol ProfileInterface: Sendable {
  func fetchMyPage() async throws -> MyPage
  func fetchRecap() async throws -> PhilosopherRecap
  func fetchCreditHistory(
    offset: Int?,
    size: Int
  ) async throws -> CreditHistoryPage
  func fetchBattleRecords(
    offset: Int,
    size: Int,
    voteSide: BattleVoteSide?
  ) async throws -> BattleRecordPage
  func fetchContentActivities(
    offset: Int,
    size: Int,
    activityType: ContentActivityType?
  ) async throws -> ContentActivityPage
  func fetchNotificationSettings() async throws -> NotificationSettings
  func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings
  func updateProfile(
    nickname: String,
    characterType: String
  ) async throws -> UpdatedProfile
}

public struct ProfileRepositoryDependency: DependencyKey {
  public static var liveValue: ProfileInterface {
    UnifiedDI.resolve(ProfileInterface.self) ?? DefaultProfileRepositoryImpl()
  }

  public static var testValue: ProfileInterface {
    UnifiedDI.resolve(ProfileInterface.self) ?? DefaultProfileRepositoryImpl()
  }

  public static var previewValue: ProfileInterface = liveValue
}

public extension DependencyValues {
  var profileRepository: ProfileInterface {
    get { self[ProfileRepositoryDependency.self] }
    set { self[ProfileRepositoryDependency.self] = newValue }
  }
}

// UseCase 소비자용 별칭 — 인터페이스 강제(구현 모듈 import 불필요). pass-through 라 리포지토리 키로 해소.
public extension DependencyValues {
  var profileUseCase: ProfileInterface {
    get { self[ProfileRepositoryDependency.self] }
    set { self[ProfileRepositoryDependency.self] = newValue }
  }
}
