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
