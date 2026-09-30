import ClassDomainInterface
import Foundation

public struct ClassRepositoryImpl: ClassInterface {
  private static let mock = MockClassRepository()

  public init() {}

  public func fetchMyClasses() async throws -> [ClassRoom] {
    try await Self.mock.fetchMyClasses()
  }

  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await Self.mock.fetchRecommendedBattles(filter: filter)
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    try await Self.mock.createClass(creation)
  }

  public func fetchClass(joinCode: String) async throws -> ClassRoom {
    try await Self.mock.fetchClass(joinCode: joinCode)
  }

  public func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    try await Self.mock.joinClass(joinCode: joinCode, nickname: nickname)
  }

  public func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    try await Self.mock.updateDeadline(id: id, deadline: deadline)
  }

  public func deleteClass(id: Int) async throws {
    try await Self.mock.deleteClass(id: id)
  }
}
