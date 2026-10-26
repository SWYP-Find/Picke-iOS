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
