import Foundation

public struct MockClassAIChatUseCase: ClassAIChatInterface {
  public var startHandler: @Sendable (UUID, ClassAIChatContext) async throws -> Void
  public var respondHandler: @Sendable (UUID, String) async throws -> String
  public var endHandler: @Sendable (UUID) async -> Void

  public init(
    start: @escaping @Sendable (UUID, ClassAIChatContext) async throws -> Void = { _, _ in },
    respond: @escaping @Sendable (UUID, String) async throws -> String = { _, text in
      "그 생각도 이해해요. 하지만 \(text)을 다른 관점에서 바라볼 수 있지 않을까요?"
    },
    end: @escaping @Sendable (UUID) async -> Void = { _ in }
  ) {
    startHandler = start
    respondHandler = respond
    endHandler = end
  }

  public func start(_ id: UUID, _ context: ClassAIChatContext) async throws {
    try await startHandler(id, context)
  }

  public func respond(_ id: UUID, _ text: String) async throws -> String {
    try await respondHandler(id, text)
  }

  public func end(_ id: UUID) async {
    await endHandler(id)
  }
}
