import ClassDomainInterface
import Dependencies
import Foundation

public struct ClassDebateUseCaseImpl: ClassDebateInterface {
  @Dependency(\.classAIRepository) private var repository

  public init() {}

  public func fetch(classID: Int) async throws -> ClassDebate {
    try await repository.fetchDebate(classID: classID)
  }

  public func start(classID: Int) async throws -> ClassDebate {
    try await repository.startDebate(classID: classID)
  }

  public func submitReply(
    classID: Int,
    round: Int,
    content: String,
    requestKey: UUID
  ) async throws -> ClassDebate {
    try await repository.submitDebateReply(
      classID: classID,
      round: round,
      content: content,
      requestKey: requestKey
    )
  }

  public func retry(classID: Int) async throws -> ClassDebate {
    try await repository.retryDebate(classID: classID)
  }
}
