//
//  ClassAIFeedbackFoundationEngine.swift
//  ClassDomain
//
//  Created by Picke on 10/12/26.
//

import ClassDomainInterface
import Foundation

#if canImport(FoundationModels)
  import FoundationModels

  @available(iOS 26.0, *)
  enum ClassAIFeedbackFoundationEngine {
    @TaskLocal static var auditDiagnostic: (@Sendable (String) -> Void)?

    private static let responseTokens = 768
    private static let headroomTokens = 128

    @Generable
    struct PersonalOutput {
      @Guide(description: "토론의 개인적 요약 제목. 한국어 1~12자")
      var summaryTitle: String
      @Guide(description: "작성한 의견에 근거한 요약 설명. 한국어 1~30자")
      var summaryDetail: String
      @Guide(description: "첫 번째 피드백 제목. 한국어 1~10자")
      var point1Title: String
      @Guide(description: "첫 번째 피드백 근거. 한국어 1~20자")
      var point1Detail: String
      @Guide(description: "두 번째 피드백 제목. 한국어 1~10자")
      var point2Title: String
      @Guide(description: "두 번째 피드백 근거. 한국어 1~20자")
      var point2Detail: String
      @Guide(description: "세 번째 피드백 제목. 한국어 1~10자")
      var point3Title: String
      @Guide(description: "세 번째 피드백 근거. 한국어 1~20자")
      var point3Detail: String
      @Guide(description: "다음 토론에서 탐구할 질문. 한국어 1~25자")
      var nextQuestion: String
      @Guide(description: "다음 질문에 접근하는 힌트. 한국어 1~15자")
      var nextHint: String
    }

    @Generable
    struct InsightOutput {
      @Guide(description: "수업 전체의 의견 흐름을 근거에 맞게 요약. 특정 개인을 평가하지 않는 한국어 1~100자")
      var paragraph: String
    }

    static func generate(context original: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult {
      try Task.checkCancellation()
      let model = SystemLanguageModel.default
      switch model.availability {
      case .available: break
      case .unavailable(.deviceNotEligible): throw ClassAIFeedbackError.deviceNotEligible
      case .unavailable(.appleIntelligenceNotEnabled): throw ClassAIFeedbackError.appleIntelligenceNotEnabled
      case .unavailable(.modelNotReady): throw ClassAIFeedbackError.modelNotReady
      @unknown default: throw ClassAIFeedbackError.deviceNotEligible
      }
      guard model.supportsLocale(Locale(identifier: "ko_KR")) else {
        throw ClassAIFeedbackError.unsupportedLanguage
      }

      var context = original
      if #unavailable(iOS 26.4) {
        context = try context.limited(
          maxExcerpts: context.kind == .classInsight ? 4 : 2,
          maxExcerptLength: 120,
          maxDataCharacters: 900
        )
      }
      for attempt in 0 ... 1 {
        try Task.checkCancellation()
        do {
          context = try await fitToContext(context, model: model)
          let instructions = ClassAIFeedbackInstructions.make(context: context)
          let prompt = ClassAIFeedbackInstructions.prompt(context: context)
          let session = LanguageModelSession(model: model, instructions: instructions)
          let options = GenerationOptions(maximumResponseTokens: responseTokens)
          switch context.kind {
          case .studentPersonal, .ownerPersonal:
            let response = try await session.respond(to: prompt, generating: PersonalOutput.self, options: options)
            try Task.checkCancellation()
            return try .personal(validatedPersonal(response.content))
          case .classInsight:
            let response = try await session.respond(to: prompt, generating: InsightOutput.self, options: options)
            try Task.checkCancellation()
            return try .classInsight(validated(response.content.paragraph, maximum: 100, field: "paragraph"))
          }
        } catch {
          if error is CancellationError {
            throw error
          }
          auditDiagnostic?("attempt=\(attempt) error=\(diagnosticCategory(error))")
          if isContextOverflow(error) {
            guard attempt == 0 else { throw ClassAIFeedbackError.contextTooLong }
            context = try context.shrunkAfterContextOverflow()
            continue
          }
          throw mapped(error)
        }
      }
      throw ClassAIFeedbackError.contextTooLong
    }

    private static func fitToContext(
      _ original: ClassAIFeedbackContext,
      model: SystemLanguageModel
    ) async throws -> ClassAIFeedbackContext {
      guard #available(iOS 26.4, *) else { return original }
      var context = original
      while true {
        try Task.checkCancellation()
        let instructions = Instructions(ClassAIFeedbackInstructions.make(context: context))
        let prompt = Prompt(ClassAIFeedbackInstructions.prompt(context: context))
        let schema = context.kind == .classInsight ? InsightOutput.generationSchema : PersonalOutput.generationSchema
        let instructionTokens = try await model.tokenCount(for: instructions)
        let promptTokens = try await model.tokenCount(for: prompt)
        let schemaTokens = try await model.tokenCount(for: schema)
        let tokens = instructionTokens + promptTokens + schemaTokens
        if tokens + responseTokens + headroomTokens <= model.contextSize {
          return context
        }
        guard context.writtenEvidence.count > 1 else { throw ClassAIFeedbackError.insufficientInput }
        context = try context.limited(
          maxExcerpts: context.writtenEvidence.count - 1,
          maxExcerptLength: 240,
          maxDataCharacters: 2400
        )
      }
    }

    private static func validatedPersonal(_ value: PersonalOutput) throws -> ClassAIPersonalFeedback {
      try ClassAIPersonalFeedback(
        summaryTitle: validated(value.summaryTitle, maximum: 12, field: "summaryTitle"),
        summaryDetail: validated(value.summaryDetail, maximum: 30, field: "summaryDetail"),
        points: [
          ClassAIFeedbackPoint(
            title: validated(value.point1Title, maximum: 10, field: "point1Title"),
            detail: validated(value.point1Detail, maximum: 20, field: "point1Detail")
          ),
          ClassAIFeedbackPoint(
            title: validated(value.point2Title, maximum: 10, field: "point2Title"),
            detail: validated(value.point2Detail, maximum: 20, field: "point2Detail")
          ),
          ClassAIFeedbackPoint(
            title: validated(value.point3Title, maximum: 10, field: "point3Title"),
            detail: validated(value.point3Detail, maximum: 20, field: "point3Detail")
          ),
        ],
        nextQuestion: validated(value.nextQuestion, maximum: 25, field: "nextQuestion"),
        nextHint: validated(value.nextHint, maximum: 15, field: "nextHint")
      )
    }

    static func validated(
      _ text: String,
      maximum: Int,
      field: String = "unspecified"
    ) throws -> String {
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else {
        auditDiagnostic?("validation=empty field=\(field) trimmedCount=0 maximum=\(maximum)")
        throw ClassAIFeedbackError.generationFailed
      }
      guard trimmed.count <= maximum else {
        auditDiagnostic?("validation=overlong field=\(field) trimmedCount=\(trimmed.count) maximum=\(maximum)")
        throw ClassAIFeedbackError.temporarilyUnavailable
      }
      return trimmed
    }

    static func diagnosticCategory(_ error: Error) -> String {
      if error is ClassAIFeedbackError {
        return "ClassAIFeedbackError"
      }
      if #available(iOS 27.0, *) {
        if let error = error as? LanguageModelError {
          switch error {
          case .unsupportedLanguageOrLocale: return "LanguageModelError.unsupportedLanguageOrLocale"
          case .rateLimited: return "LanguageModelError.rateLimited"
          case .timeout: return "LanguageModelError.timeout"
          case .contextSizeExceeded: return "LanguageModelError.contextSizeExceeded"
          case .guardrailViolation: return "LanguageModelError.guardrailViolation"
          case .refusal: return "LanguageModelError.refusal"
          case .unsupportedCapability: return "LanguageModelError.unsupportedCapability"
          case .unsupportedTranscriptContent: return "LanguageModelError.unsupportedTranscriptContent"
          case .unsupportedGenerationGuide: return "LanguageModelError.unsupportedGenerationGuide"
          @unknown default: return "LanguageModelError.unclassified"
          }
        }
        if let error = error as? SystemLanguageModel.Error {
          switch error {
          case .assetsUnavailable: return "SystemLanguageModel.Error.assetsUnavailable"
          @unknown default: return "SystemLanguageModel.Error.unclassified"
          }
        }
        if let error = error as? LanguageModelSession.Error {
          switch error {
          case .concurrentRequests: return "LanguageModelSession.Error.concurrentRequests"
          case .transcriptMutationWhileResponding: return "LanguageModelSession.Error.transcriptMutationWhileResponding"
          @unknown default: return "LanguageModelSession.Error.unclassified"
          }
        }
      }
      if let error = error as? LanguageModelSession.GenerationError {
        switch error {
        case .unsupportedLanguageOrLocale: return "GenerationError.unsupportedLanguageOrLocale"
        case .assetsUnavailable: return "GenerationError.assetsUnavailable"
        case .rateLimited: return "GenerationError.rateLimited"
        case .concurrentRequests: return "GenerationError.concurrentRequests"
        case .exceededContextWindowSize: return "GenerationError.exceededContextWindowSize"
        case .guardrailViolation: return "GenerationError.guardrailViolation"
        case .unsupportedGuide: return "GenerationError.unsupportedGuide"
        case .decodingFailure: return "GenerationError.decodingFailure"
        case .refusal: return "GenerationError.refusal"
        @unknown default: return "GenerationError.unclassified"
        }
      }
      return "unclassified"
    }

    static func isContextOverflow(_ error: Error) -> Bool {
      if #available(iOS 27.0, *), let modelError = error as? LanguageModelError {
        if case .contextSizeExceeded = modelError {
          return true
        }
      }
      if let modelError = error as? LanguageModelSession.GenerationError {
        if case .exceededContextWindowSize = modelError {
          return true
        }
      }
      return false
    }

    static func mapped(_ error: Error) -> Error {
      if let feedbackError = error as? ClassAIFeedbackError {
        return feedbackError
      }
      if #available(iOS 27.0, *) {
        if let modelError = error as? LanguageModelError {
          switch modelError {
          case .unsupportedLanguageOrLocale: return ClassAIFeedbackError.unsupportedLanguage
          case .rateLimited, .timeout: return ClassAIFeedbackError.temporarilyUnavailable
          case .contextSizeExceeded: return ClassAIFeedbackError.contextTooLong
          case .guardrailViolation, .refusal, .unsupportedCapability, .unsupportedTranscriptContent,
               .unsupportedGenerationGuide: return ClassAIFeedbackError.generationFailed
          @unknown default: return error
          }
        }
        if let modelError = error as? SystemLanguageModel.Error {
          switch modelError {
          case .assetsUnavailable: return ClassAIFeedbackError.temporarilyUnavailable
          @unknown default: return error
          }
        }
        if let sessionError = error as? LanguageModelSession.Error {
          switch sessionError {
          case .concurrentRequests: return ClassAIFeedbackError.temporarilyUnavailable
          case .transcriptMutationWhileResponding: return ClassAIFeedbackError.generationFailed
          @unknown default: return error
          }
        }
      }
      if let modelError = error as? LanguageModelSession.GenerationError {
        switch modelError {
        case .unsupportedLanguageOrLocale: return ClassAIFeedbackError.unsupportedLanguage
        case .assetsUnavailable, .rateLimited, .concurrentRequests:
          return ClassAIFeedbackError.temporarilyUnavailable
        case .exceededContextWindowSize: return ClassAIFeedbackError.contextTooLong
        case .guardrailViolation, .unsupportedGuide, .decodingFailure, .refusal:
          return ClassAIFeedbackError.generationFailed
        @unknown default: return error
        }
      }
      return error
    }
  }
#endif
