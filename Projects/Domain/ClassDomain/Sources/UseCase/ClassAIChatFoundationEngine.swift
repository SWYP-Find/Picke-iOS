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

    private var sessions: [UUID: LanguageModelSession] = [:]
    private var respondingIDs: Set<UUID> = []

    func start(id: UUID, context: ClassAIChatContext) throws {
      let model = SystemLanguageModel.default
      switch model.availability {
      case .available:
        break
      case .unavailable(.deviceNotEligible):
        throw ClassAIChatError.deviceNotEligible
      case .unavailable(.appleIntelligenceNotEnabled):
        throw ClassAIChatError.appleIntelligenceNotEnabled
      case .unavailable(.modelNotReady):
        throw ClassAIChatError.modelNotReady
      @unknown default:
        throw ClassAIChatError.unavailable
      }
      guard model.supportsLocale(Locale(identifier: "ko_KR")) else {
        throw ClassAIChatError.unsupportedLanguage
      }
      let instructions = ClassAIChatInstructions.make(context: context)
      let session = LanguageModelSession(model: model, instructions: instructions)
      session.prewarm()
      sessions[id] = session
    }

    func respond(id: UUID, text: String) async throws -> String {
      guard let session = sessions[id] else { throw ClassAIChatError.noSession }
      guard !respondingIDs.contains(id) else { throw ClassAIChatError.alreadyResponding }
      respondingIDs.insert(id)
      defer { respondingIDs.remove(id) }
      let response = try await session.respond(to: text)
      return String(response.content.prefix(600))
    }

    func end(id: UUID) {
      sessions[id] = nil
      respondingIDs.remove(id)
    }
  }
#endif
