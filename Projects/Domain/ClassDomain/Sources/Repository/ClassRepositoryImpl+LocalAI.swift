import ClassDomainInterface
import Foundation

extension ClassRepositoryImpl {
  public func startAIChat(_ id: UUID, _ context: ClassAIChatContext) async throws {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        try await ClassAIChatFoundationEngine.shared.start(id: id, context: context)
        return
      }
    #endif
    throw ClassAIChatError.unavailable
  }

  public func respondAIChat(_ id: UUID, _ text: String, isFinalRound: Bool) async throws -> String {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        return try await ClassAIChatFoundationEngine.shared.respond(
          id: id,
          text: text,
          isFinalRound: isFinalRound
        )
      }
    #endif
    throw ClassAIChatError.unavailable
  }

  public func endAIChat(_ id: UUID) async {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        await ClassAIChatFoundationEngine.shared.end(id: id)
      }
    #endif
  }

  public func generateAIFeedback(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        return try await ClassAIFeedbackFoundationEngine.generate(context: context)
      }
    #endif
    throw ClassAIFeedbackError.deviceNotEligible
  }
}
