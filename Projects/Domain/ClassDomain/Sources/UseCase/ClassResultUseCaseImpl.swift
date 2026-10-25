import ClassDomainInterface
import Dependencies

public struct ClassResultUseCaseImpl: ClassResultInterface {
  @Dependency(\.classResultRepository) private var repository

  public init() {}

  public func fetch(roomID: Int) async throws -> ClassResult {
    try await repository.fetch(roomID: roomID)
  }

  public func fetchPersonal(roomID: Int) async throws -> ClassAIPersonalFeedback {
    try await repository.fetchPersonal(roomID: roomID)
  }

  public func fetchInsight(roomID: Int) async throws -> ClassAIInsight {
    try await repository.fetchInsight(roomID: roomID)
  }

  public func retryInsight(roomID: Int) async throws {
    try await repository.retryInsight(roomID: roomID)
  }
}
