import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func startAIChat(_ id: UUID, _ context: ClassAIChatContext) async throws {
    try await repository.startAIChat(id, context)
  }

  public func respondAIChat(_ id: UUID, _ text: String, isFinalRound: Bool) async throws -> String {
    try await repository.respondAIChat(id, text, isFinalRound: isFinalRound)
  }

  public func endAIChat(_ id: UUID) async {
    await repository.endAIChat(id)
  }

  public func generateAIFeedback(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult {
    try await repository.generateAIFeedback(context: context)
  }
}
