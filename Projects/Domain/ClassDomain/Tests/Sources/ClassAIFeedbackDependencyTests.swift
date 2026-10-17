//
//  ClassAIFeedbackDependencyTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/12/26.
//

@testable import ClassDomain
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

#if canImport(FoundationModels)
  import FoundationModels
#endif

struct ClassAIFeedbackDependencyTests {
  @Test
  func dependencyCanBeInjectedAndErrorBucketsAreStable() async throws {
    let context = try ClassAIFeedbackContext.personal(
      room: .mockClosedSociety,
      report: MockClassReport.figma,
      isOwner: false
    )
    let mock = MockClassAIFeedbackUseCase { received in
      #expect(received.roomID == context.roomID)
      return .classInsight("generated")
    }
    let useCase = withDependencies {
      $0.classAIFeedbackUseCase = mock
    } operation: {
      @Dependency(\.classAIFeedbackUseCase) var useCase
      return useCase
    }
    let result = try await useCase.generate(context: context)
    #expect(result == .classInsight("generated"))
    #expect(ClassAIFeedbackError.deviceNotEligible.isUnavailable)
    #expect(ClassAIFeedbackError.appleIntelligenceNotEnabled.isUnavailable)
    #expect(ClassAIFeedbackError.unsupportedLanguage.isUnavailable)
    #expect(ClassAIFeedbackError.modelNotReady.isRetryable)
    #expect(ClassAIFeedbackError.temporarilyUnavailable.isRetryable)
    #expect(!ClassAIFeedbackError.generationFailed.isRetryable)
  }

  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    @Test
    func legacySDKErrorMapCoversRetryAndTerminalBuckets() {
      let context = LanguageModelSession.GenerationError.Context(debugDescription: "test")
      let errors: [(any Error, ClassAIFeedbackError)] = [
        (LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(context), .unsupportedLanguage),
        (LanguageModelSession.GenerationError.assetsUnavailable(context), .temporarilyUnavailable),
        (LanguageModelSession.GenerationError.rateLimited(context), .temporarilyUnavailable),
        (LanguageModelSession.GenerationError.concurrentRequests(context), .temporarilyUnavailable),
        (LanguageModelSession.GenerationError.exceededContextWindowSize(context), .contextTooLong),
        (LanguageModelSession.GenerationError.guardrailViolation(context), .generationFailed),
        (LanguageModelSession.GenerationError.unsupportedGuide(context), .generationFailed),
        (LanguageModelSession.GenerationError.decodingFailure(context), .generationFailed),
        (
          LanguageModelSession.GenerationError.refusal(.init(transcriptEntries: []), context),
          .generationFailed
        ),
      ]
      for (error, expected) in errors {
        #expect((ClassAIFeedbackFoundationEngine.mapped(error) as? ClassAIFeedbackError) == expected)
      }
      #expect(ClassAIFeedbackFoundationEngine.isContextOverflow(
        LanguageModelSession.GenerationError.exceededContextWindowSize(context)
      ))
    }

    @available(iOS 27.0, *)
    @Test
    func modernSDKErrorMapCoversRetryAndTerminalBuckets() {
      let errors: [(any Error, ClassAIFeedbackError)] = [
        (
          LanguageModelError.unsupportedLanguageOrLocale(
            .init(languageCode: .init("ko"), debugDescription: "test")
          ),
          .unsupportedLanguage
        ),
        (LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: "test")), .temporarilyUnavailable),
        (LanguageModelError.timeout(.init(debugDescription: "test")), .temporarilyUnavailable),
        (
          LanguageModelError.contextSizeExceeded(
            .init(contextSize: 4096, tokenCount: 4200, debugDescription: "test")
          ),
          .contextTooLong
        ),
        (LanguageModelError.guardrailViolation(.init(debugDescription: "test")), .generationFailed),
        (LanguageModelError.refusal(.init(explanation: "test", debugDescription: "test")), .generationFailed),
        (
          LanguageModelError.unsupportedCapability(
            .init(capability: .guidedGeneration, debugDescription: "test")
          ),
          .generationFailed
        ),
        (
          LanguageModelError.unsupportedTranscriptContent(
            .init(unsupportedContent: [], debugDescription: "test")
          ),
          .generationFailed
        ),
        (
          LanguageModelError.unsupportedGenerationGuide(
            .init(schemaName: nil, debugDescription: "test")
          ),
          .generationFailed
        ),
        (SystemLanguageModel.Error.assetsUnavailable(.init(debugDescription: "test")), .temporarilyUnavailable),
        (LanguageModelSession.Error.concurrentRequests, .temporarilyUnavailable),
        (LanguageModelSession.Error.transcriptMutationWhileResponding, .generationFailed),
      ]
      for (error, expected) in errors {
        #expect((ClassAIFeedbackFoundationEngine.mapped(error) as? ClassAIFeedbackError) == expected)
      }
      #expect(ClassAIFeedbackFoundationEngine.isContextOverflow(
        LanguageModelError.contextSizeExceeded(.init(contextSize: 4096, tokenCount: 4200, debugDescription: "test"))
      ))
    }

    @available(iOS 26.0, *)
    @Test
    func unrecognizedErrorKeepsItsIdentityForBoundedFeatureRetry() {
      struct UnexpectedModelError: Error {}
      let mapped = ClassAIFeedbackFoundationEngine.mapped(UnexpectedModelError())
      #expect(mapped is UnexpectedModelError)
      #expect(!(mapped is ClassAIFeedbackError))
    }
  #endif
}
