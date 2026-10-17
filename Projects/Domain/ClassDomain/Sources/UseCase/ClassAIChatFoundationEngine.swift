//
//  ClassAIChatFoundationEngine.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import Foundation

#if canImport(FoundationModels)
  import FoundationModels

  @available(iOS 26.0, *)
  actor ClassAIChatFoundationEngine {
    static let shared = ClassAIChatFoundationEngine()

    private static let responseTokens = 384
    private static let finalResponseTokens = 768
    private static let headroomTokens = 128

    private var sessions: [UUID: LanguageModelSession] = [:]
    private var contexts: [UUID: ClassAIChatContext] = [:]
    private var respondingSessions: [UUID: LanguageModelSession] = [:]
    private var needsReset: Set<UUID> = []
    private var history = ClassAIChatHistory()

    func start(id: UUID, context: ClassAIChatContext) throws {
      let model = try availableModel()
      let session = makeSession(model: model, context: context)
      contexts[id] = context
      let historyLimit = if #available(iOS 26.4, *) {
        1440
      } else {
        720
      }
      history.prepare(
        id: id,
        messages: context.priorMessages,
        maximumCharacters: historyLimit
      )
      needsReset.remove(id)
      respondingSessions[id] = nil
      sessions[id] = session
    }

    func respond(
      id: UUID,
      text: String,
      isFinalRound: Bool
    ) async throws -> String {
      guard var session = sessions[id] else { throw ClassAIChatError.noSession }
      guard respondingSessions[id] == nil else { throw ClassAIChatError.alreadyResponding }

      if needsReset.contains(id) {
        guard let context = contexts[id] else { throw ClassAIChatError.noSession }
        let model = try availableModel()
        guard sessions[id] === session else { throw CancellationError() }
        session = makeSession(model: model, context: context)
        sessions[id] = session
        needsReset.remove(id)
      }

      respondingSessions[id] = session
      defer {
        if respondingSessions[id] === session {
          respondingSessions[id] = nil
        }
      }

      var beforeTranscript: [Transcript.Entry]?
      do {
        let prompt = try await fittingPrompt(
          id: id,
          session: session,
          text: text,
          isFinalRound: isFinalRound
        )
        try requireCurrent(id: id, session: session)
        beforeTranscript = Array(session.transcript)
        let content: String
        if isFinalRound {
          let response = try await session.respond(
            to: prompt,
            generating: ClassAIChatFinalSynthesis.self,
            options: GenerationOptions(maximumResponseTokens: Self.finalResponseTokens)
          )
          try requireCurrent(id: id, session: session)
          content = try response.content.validatedContent()
        } else {
          let response = try await session.respond(
            to: prompt,
            options: GenerationOptions(maximumResponseTokens: Self.responseTokens)
          )
          try requireCurrent(id: id, session: session)
          content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !content.isEmpty else {
          if history.emptyResponse(id: id) {
            needsReset.insert(id)
          }
          throw ClassAIChatError.emptyResponse
        }
        history.succeeded(id: id, response: content)
        return content
      } catch {
        try Task.checkCancellation()
        try requireCurrent(id: id, session: session)
        let isCancellation = error is CancellationError
        let mapped = isCancellation ? nil : Self.mapped(error, isFinalRound: isFinalRound)
        if mapped == .finalSummaryInvalid, let beforeTranscript {
          sessions[id] = try Self.restoredSession(
            current: sessions[id],
            captured: session,
            model: SystemLanguageModel.default,
            entries: beforeTranscript
          )
          respondingSessions[id] = nil
          throw ClassAIChatError.finalSummaryInvalid
        }
        // iOS 26 post-error transcript retention remains unverified on an eligible device.
        // Only a pending re-entry history prompt is reset when it was actually recorded.
        if mapped != .emptyResponse, let beforeTranscript, #unavailable(iOS 27.0) {
          let newEntries = Array(session.transcript).dropFirst(beforeTranscript.count)
          let promptRecorded = newEntries.contains { entry in
            if case .prompt = entry {
              return true
            }
            return false
          }
          if history.failed(id: id, promptRecorded: promptRecorded) {
            needsReset.insert(id)
          }
        }
        if isCancellation {
          throw error
        }
        guard let mapped else { throw error }
        if mapped.isTerminal {
          end(id: id)
        }
        throw mapped
      }
    }

    func end(id: UUID) {
      sessions[id] = nil
      contexts[id] = nil
      respondingSessions[id] = nil
      needsReset.remove(id)
      history.end(id: id)
    }

    private func availableModel() throws -> SystemLanguageModel {
      let model = SystemLanguageModel.default
      switch model.availability {
      case .available: break
      case .unavailable(.deviceNotEligible): throw ClassAIChatError.deviceNotEligible
      case .unavailable(.appleIntelligenceNotEnabled): throw ClassAIChatError.appleIntelligenceNotEnabled
      case .unavailable(.modelNotReady): throw ClassAIChatError.modelNotReady
      @unknown default: throw ClassAIChatError.unavailable
      }
      guard model.supportsLocale(Locale(identifier: "ko_KR")) else {
        throw ClassAIChatError.unsupportedLanguage
      }
      return model
    }

    private func makeSession(
      model: SystemLanguageModel,
      context: ClassAIChatContext
    ) -> LanguageModelSession {
      let session = LanguageModelSession(
        model: model,
        instructions: ClassAIChatInstructions.make(context: context)
      )
      if #available(iOS 27.0, *) {
        session.transcriptErrorHandlingPolicy = .revertTranscript
      }
      session.prewarm()
      return session
    }

    static func restoredSession(
      current: LanguageModelSession?,
      captured: LanguageModelSession,
      model: SystemLanguageModel,
      entries: [Transcript.Entry]
    ) throws -> LanguageModelSession {
      guard current === captured else { throw CancellationError() }
      let session = LanguageModelSession(model: model, transcript: Transcript(entries: entries))
      if #available(iOS 27.0, *) {
        session.transcriptErrorHandlingPolicy = .revertTranscript
      }
      session.prewarm()
      return session
    }

    private func fittingPrompt(
      id: UUID,
      session: LanguageModelSession,
      text: String,
      isFinalRound: Bool
    ) async throws -> String {
      guard #available(iOS 26.4, *) else {
        return history.prompt(id: id, userText: text, isFinalRound: isFinalRound)
      }
      let model = SystemLanguageModel.default
      while true {
        try Task.checkCancellation()
        let transcriptTokens = try await model.tokenCount(for: Array(session.transcript))
        try requireCurrent(id: id, session: session)
        let prompt = history.prompt(id: id, userText: text, isFinalRound: isFinalRound)
        let promptTokens = try await model.tokenCount(for: Prompt(prompt))
        try requireCurrent(id: id, session: session)
        let schemaTokens: Int
        if isFinalRound {
          schemaTokens = try await model.tokenCount(for: ClassAIChatFinalSynthesis.generationSchema)
          try requireCurrent(id: id, session: session)
        } else {
          schemaTokens = 0
        }
        let responseTokens = isFinalRound ? Self.finalResponseTokens : Self.responseTokens
        if transcriptTokens + promptTokens + schemaTokens + responseTokens + Self.headroomTokens <= model.contextSize {
          return prompt
        }
        guard history.dropOldestPendingTurn(id: id) else {
          throw ClassAIChatError.contextExhausted
        }
      }
    }

    private func requireCurrent(
      id: UUID,
      session: LanguageModelSession
    ) throws {
      guard sessions[id] === session else { throw CancellationError() }
    }

    static func mapped(
      _ error: Error,
      isFinalRound: Bool = false
    ) -> ClassAIChatError {
      if let chatError = error as? ClassAIChatError {
        return chatError
      }
      if #available(iOS 27.0, *) {
        if error is GeneratedContent.ParsingError {
          return isFinalRound ? .finalSummaryInvalid : .invalidOutput
        }
        if let modelError = error as? LanguageModelError {
          switch modelError {
          case .guardrailViolation, .refusal: return .contentRejected
          case .contextSizeExceeded: return .contextExhausted
          case .unsupportedCapability, .unsupportedTranscriptContent, .unsupportedGenerationGuide:
            return .invalidOutput
          case .unsupportedLanguageOrLocale: return .unsupportedLanguage
          case .rateLimited, .timeout: return .temporarilyUnavailable
          @unknown default: return .unexpectedFailure
          }
        }
        if let modelError = error as? SystemLanguageModel.Error {
          switch modelError {
          case .assetsUnavailable: return .modelNotReady
          @unknown default: return .unexpectedFailure
          }
        }
        if let sessionError = error as? LanguageModelSession.Error {
          switch sessionError {
          case .concurrentRequests: return .temporarilyUnavailable
          case .transcriptMutationWhileResponding: return .invalidOutput
          @unknown default: return .unexpectedFailure
          }
        }
      }
      if let modelError = error as? LanguageModelSession.GenerationError {
        switch modelError {
        case .guardrailViolation, .refusal: return .contentRejected
        case .exceededContextWindowSize: return .contextExhausted
        case .unsupportedGuide: return .invalidOutput
        case .decodingFailure: return isFinalRound ? .finalSummaryInvalid : .invalidOutput
        case .unsupportedLanguageOrLocale: return .unsupportedLanguage
        case .assetsUnavailable: return .modelNotReady
        case .rateLimited, .concurrentRequests: return .temporarilyUnavailable
        @unknown default: return .unexpectedFailure
        }
      }
      return .unexpectedFailure
    }
  }
#endif
