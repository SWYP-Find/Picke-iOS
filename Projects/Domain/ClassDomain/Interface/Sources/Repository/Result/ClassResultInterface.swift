//
//  ClassResultInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/26/26.
//

import ComposableArchitecture
import Foundation

public protocol ClassResultInterface: Sendable {
  func fetchResult(roomID: Int) async throws -> ClassResult
  func fetchPersonalResult(roomID: Int) async throws -> ClassAIPersonalFeedback
  func fetchInsight(roomID: Int) async throws -> ClassAIInsight
  func retryInsight(roomID: Int) async throws
  /// Android `GET /result/insight` — 상태를 그대로 받는다.
  func fetchInsightBoard(roomID: Int) async throws -> ClassResultInsightBoard
  /// Android `GET /result/my-report` — 상태를 그대로 받는다.
  func fetchMyReportBoard(roomID: Int) async throws -> ClassResultMyReportBoard
  func fetchMyActivity(
    roomID: Int,
    cursor: String?
  ) async throws -> ClassMyActivity
}

public extension ClassResultInterface {
  /// 상태 보존 조회를 구현하지 않은 테스트 대역용 기본 구현.
  func fetchInsightBoard(roomID _: Int) async throws -> ClassResultInsightBoard {
    throw ClassError.unknown("인사이트를 불러올 수 없습니다.")
  }

  func fetchMyReportBoard(roomID _: Int) async throws -> ClassResultMyReportBoard {
    throw ClassError.unknown("내 리포트를 불러올 수 없습니다.")
  }
}

public enum ClassResultRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassResultInterface {
    MockClassRepository()
  }
}

public enum ClassResultUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassResultInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classResultRepository: any ClassResultInterface {
    get { self[ClassResultRepositoryDependency.self] }
    set { self[ClassResultRepositoryDependency.self] = newValue }
  }

  var classResultUseCase: any ClassResultInterface {
    get { self[ClassResultUseCaseDependency.self] }
    set { self[ClassResultUseCaseDependency.self] = newValue }
  }
}
