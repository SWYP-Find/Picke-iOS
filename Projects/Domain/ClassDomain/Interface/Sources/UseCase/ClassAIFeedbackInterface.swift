//
//  ClassAIFeedbackInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/12/26.
//

import ComposableArchitecture

public protocol ClassAIFeedbackInterface: Sendable {
  func generate(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult
}

public enum ClassAIFeedbackUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassAIFeedbackInterface {
    MockClassAIFeedbackUseCase()
  }

  public static var previewValue: any ClassAIFeedbackInterface {
    MockClassAIFeedbackUseCase()
  }
}

public extension DependencyValues {
  var classAIFeedbackUseCase: any ClassAIFeedbackInterface {
    get { self[ClassAIFeedbackUseCaseDependency.self] }
    set { self[ClassAIFeedbackUseCaseDependency.self] = newValue }
  }
}
