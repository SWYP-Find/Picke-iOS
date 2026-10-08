import ClassDomainInterface
import Foundation

public struct ClassAIChatUseCaseImpl: ClassAIChatInterface {
  public init() {}

  public func start(_ id: UUID, _ context: ClassAIChatContext) async throws {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        try await ClassAIChatFoundationEngine.shared.start(id: id, context: context)
        return
      }
    #endif
    throw ClassAIChatError.unavailable
  }

  public func respond(_ id: UUID, _ text: String) async throws -> String {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        return try await ClassAIChatFoundationEngine.shared.respond(id: id, text: text)
      }
    #endif
    throw ClassAIChatError.unavailable
  }

  public func end(_ id: UUID) async {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        await ClassAIChatFoundationEngine.shared.end(id: id)
      }
    #endif
  }
}
