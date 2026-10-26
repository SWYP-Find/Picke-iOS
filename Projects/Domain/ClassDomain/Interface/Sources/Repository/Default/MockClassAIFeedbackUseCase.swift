//
//  MockClassAIFeedbackUseCase.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/12/26.
//

public struct MockClassAIFeedbackUseCase {
  public var generateHandler: @Sendable (ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult

  public init(
    generate: @escaping @Sendable (ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult = { _ in
      throw ClassAIFeedbackError.modelNotReady
    }
  ) {
    generateHandler = generate
  }

  public func generate(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult {
    try await generateHandler(context)
  }
}
