//
//  ProfileInterface.swift
//  DomainInterface
//

import Entity
import Foundation
import WeaveDI

public protocol ProfileInterface: Sendable {
  func fetchMyPage() async throws -> MyPage
  func fetchCreditHistory(
    offset: Int,
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
