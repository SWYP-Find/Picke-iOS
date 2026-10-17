//
//  ClassAIFeedbackUseCaseImpl.swift
//  ClassDomain
//
//  Created by Picke on 10/12/26.
//

import ClassDomainInterface

public struct ClassAIFeedbackUseCaseImpl: ClassAIFeedbackInterface {
  public init() {}

  public func generate(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        return try await ClassAIFeedbackFoundationEngine.generate(context: context)
      }
    #endif
    throw ClassAIFeedbackError.deviceNotEligible
  }
}
