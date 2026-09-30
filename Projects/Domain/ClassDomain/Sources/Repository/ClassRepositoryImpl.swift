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
}
