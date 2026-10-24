import ClassDomainInterface
import ComposableArchitecture
import Foundation

public struct ClassBattleUseCaseImpl: ClassBattleInterface {
  @Dependency(\.classBattleRepository) private var repository

  public init() {}

  public func fetchBattle(classID: Int) async throws -> ClassBattleSession {
    try await repository.fetchBattle(classID: classID)
  }

  public func submitPreVote(
    classID: Int,
    optionID: Int
  ) async throws -> ClassVoteReceipt {
    try await repository.submitPreVote(classID: classID, optionID: optionID)
  }

  public func completeTTS(classID: Int) async throws {
    try await repository.completeTTS(classID: classID)
  }

  public func submitPostVote(
    classID: Int,
    optionID: Int
  ) async throws -> ClassVoteReceipt {
    try await repository.submitPostVote(classID: classID, optionID: optionID)
  }

  public func fetchMyVotes(classID: Int) async throws -> ClassVoteHistory {
    try await repository.fetchMyVotes(classID: classID)
  }

  public func fetchVoteStats(classID: Int) async throws -> ClassVoteStats {
    try await repository.fetchVoteStats(classID: classID)
  }

  public func publishPerspective(
    classID: Int,
    content: String
  ) async throws -> ClassPerspectiveReceipt {
    try await repository.publishPerspective(classID: classID, content: content)
  }

  public func fetchPerspectives(
    classID: Int,
    cursor: String?,
    size: Int?,
    optionID: Int?,
    sort: String?
  ) async throws -> ClassPerspectivePage {
    try await repository.fetchPerspectives(
      classID: classID,
      cursor: cursor,
      size: size,
      optionID: optionID,
      sort: sort
    )
  }

  public func fetchMyPerspectives(classID: Int) async throws -> [ClassPerspectiveItem] {
    try await repository.fetchMyPerspectives(classID: classID)
  }
}
