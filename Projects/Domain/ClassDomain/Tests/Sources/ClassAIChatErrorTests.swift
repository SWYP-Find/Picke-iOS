//
//  ClassAIChatErrorTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/12/26.
//

@testable import ClassDomain
import ClassDomainInterface
import Testing

#if canImport(FoundationModels)
  import FoundationModels
#endif

struct ClassAIChatErrorTests {
  @Test
  func 개시_재시도와_변경필요_종료_정책을_구분한다() {
    #expect(ClassAIChatError.contentRejected.requiresChangedInput)
    #expect(!ClassAIChatError.emptyResponse.requiresChangedInput)
    #expect(ClassAIChatError.emptyResponse.canRetryOpening)
    #expect(ClassAIChatError.modelNotReady.canRetryOpening)
    #expect(ClassAIChatError.temporarilyUnavailable.canRetryOpening)
    #expect(!ClassAIChatError.contentRejected.canRetryOpening)
    #expect(ClassAIChatError.contextExhausted.isTerminal)
    #expect(ClassAIChatError.invalidOutput.isTerminal)
    #expect(!ClassAIChatError.emptyResponse.isTerminal)
  }

  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    @Test
    func 이전_SDK_오류를_토론_정책에_대응한다() {
      let context = LanguageModelSession.GenerationError.Context(debugDescription: "test")
      let cases: [(any Error, ClassAIChatError)] = [
        (LanguageModelSession.GenerationError.guardrailViolation(context), .contentRejected),
        (LanguageModelSession.GenerationError.refusal(.init(transcriptEntries: []), context), .contentRejected),
        (LanguageModelSession.GenerationError.exceededContextWindowSize(context), .contextExhausted),
        (LanguageModelSession.GenerationError.unsupportedGuide(context), .invalidOutput),
        (LanguageModelSession.GenerationError.decodingFailure(context), .invalidOutput),
        (LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(context), .unsupportedLanguage),
        (LanguageModelSession.GenerationError.assetsUnavailable(context), .modelNotReady),
        (LanguageModelSession.GenerationError.rateLimited(context), .temporarilyUnavailable),
        (LanguageModelSession.GenerationError.concurrentRequests(context), .temporarilyUnavailable),
      ]
      for (error, expected) in cases {
        #expect(ClassAIChatFoundationEngine.mapped(error) == expected)
      }
    }

    @available(iOS 27.0, *)
    @Test
    func 현재_SDK_오류를_토론_정책에_대응한다() {
      let cases: [(any Error, ClassAIChatError)] = [
        (LanguageModelError.guardrailViolation(.init(debugDescription: "test")), .contentRejected),
        (LanguageModelError.refusal(.init(explanation: "test", debugDescription: "test")), .contentRejected),
        (
          LanguageModelError.contextSizeExceeded(
            .init(contextSize: 4096, tokenCount: 4200, debugDescription: "test")
          ),
          .contextExhausted
        ),
        (
          LanguageModelError.unsupportedCapability(
            .init(capability: .guidedGeneration, debugDescription: "test")
          ),
          .invalidOutput
        ),
        (
          LanguageModelError.unsupportedTranscriptContent(
            .init(unsupportedContent: [], debugDescription: "test")
          ),
          .invalidOutput
        ),
        (
          LanguageModelError.unsupportedGenerationGuide(
            .init(schemaName: nil, debugDescription: "test")
          ),
          .invalidOutput
        ),
        (
          LanguageModelError.unsupportedLanguageOrLocale(
            .init(languageCode: .init("ko"), debugDescription: "test")
          ),
          .unsupportedLanguage
        ),
        (LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: "test")), .temporarilyUnavailable),
        (LanguageModelError.timeout(.init(debugDescription: "test")), .temporarilyUnavailable),
        (SystemLanguageModel.Error.assetsUnavailable(.init(debugDescription: "test")), .modelNotReady),
        (LanguageModelSession.Error.concurrentRequests, .temporarilyUnavailable),
        (LanguageModelSession.Error.transcriptMutationWhileResponding, .invalidOutput),
        (GeneratedContent.ParsingError(rawContent: "", debugDescription: "test"), .invalidOutput),
      ]
      for (error, expected) in cases {
        #expect(ClassAIChatFoundationEngine.mapped(error) == expected)
      }
    }
  #endif
}
