//
//  HomeInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation
import ComposableArchitecture

/// 홈 화면 데이터 조회 Repository 인터페이스.
public protocol HomeInterface: Sendable {
  func fetchHome() async throws -> HomeBundle
}

// MARK: - Dependency

public enum HomeRepositoryDependency: TestDependencyKey {
  public static var testValue: HomeInterface { MockHomeRepository() }
}

public enum HomeUseCaseDependency: TestDependencyKey {
  public static var testValue: HomeInterface { MockHomeRepository() }
}

public extension DependencyValues {
  var homeRepository: HomeInterface {
    get { self[HomeRepositoryDependency.self] }
    set { self[HomeRepositoryDependency.self] = newValue }
  }
}

// UseCase 소비자용 별칭 — 인터페이스 강제(구현 모듈 import 불필요). pass-through 라 리포지토리 키로 해소.
public extension DependencyValues {
  var homeUseCase: HomeInterface {
    get { self[HomeUseCaseDependency.self] }
    set { self[HomeUseCaseDependency.self] = newValue }
  }
}
