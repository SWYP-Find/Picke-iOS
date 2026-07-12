//
//  HomeInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation
import WeaveDI

/// 홈 화면 데이터 조회 Repository 인터페이스.
public protocol HomeInterface: Sendable {
  func fetchHome() async throws -> HomeBundle
}

// MARK: - Dependency

public struct HomeRepositoryDependency: DependencyKey {
  public static var liveValue: HomeInterface {
    return UnifiedDI.resolve(HomeInterface.self) ?? DefaultHomeRepositoryImpl()
  }

  public static var testValue: HomeInterface {
    return UnifiedDI.resolve(HomeInterface.self) ?? DefaultHomeRepositoryImpl()
  }

  public static var previewValue: HomeInterface = liveValue
}

public extension DependencyValues {
  var homeRepository: HomeInterface {
    get { self[HomeRepositoryDependency.self] }
    set { self[HomeRepositoryDependency.self] = newValue }
  }
}
