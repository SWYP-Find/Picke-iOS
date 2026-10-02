import ClassDomainInterface
import ComposableArchitecture
import Foundation

public struct ClassUseCaseImpl: ClassInterface {
  @Dependency(\.classRepository) private var repository

  public init() {}

  public func fetchMyClasses() async throws -> [ClassRoom] {
    try await repository.fetchMyClasses()
  }

  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await repository.fetchRecommendedBattles(filter: filter)
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    try await repository.createClass(creation)
  }

  public func fetchClass(joinCode: String) async throws -> ClassRoom {
    try await repository.fetchClass(joinCode: joinCode)
  }

  public func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    try await repository.joinClass(joinCode: joinCode, nickname: nickname)
  }

  public func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    try await repository.updateDeadline(id: id, deadline: deadline)
  }

  public func deleteClass(id: Int) async throws {
    try await repository.deleteClass(id: id)
  }
}
