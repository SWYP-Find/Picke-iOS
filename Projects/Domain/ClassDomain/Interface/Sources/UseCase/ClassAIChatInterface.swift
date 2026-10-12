//
//  ClassAIChatInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import Foundation

public protocol ClassAIChatInterface: Sendable {
  func start(_ id: UUID, _ context: ClassAIChatContext) async throws
  /// `isFinalRound` 가 참이면 질문 없이 논점을 정리하며 토론을 마무리하는 답변을 만든다.
  func respond(
    _ id: UUID,
    _ text: String,
    isFinalRound: Bool
  ) async throws -> String
  func end(_ id: UUID) async
}

public enum ClassAIChatUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassAIChatInterface {
    MockClassAIChatUseCase()
  }

  public static var previewValue: any ClassAIChatInterface {
    MockClassAIChatUseCase()
  }
}

public extension DependencyValues {
  var classAIChatUseCase: any ClassAIChatInterface {
    get { self[ClassAIChatUseCaseDependency.self] }
    set { self[ClassAIChatUseCaseDependency.self] = newValue }
  }
}
