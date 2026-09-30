import ClassDomainInterface
import Foundation

public struct ClassRepositoryImpl: ClassInterface {
  private let mock = MockClassRepository()

  public init() {}

  public func fetchMyClasses() async throws -> [ClassRoom] {
    try await mock.fetchMyClasses()
  }

  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await mock.fetchRecommendedBattles(filter: filter)
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    try await mock.createClass(creation)
  }

  public func fetchClass(joinCode: String) async throws -> ClassRoom {
    try await mock.fetchClass(joinCode: joinCode)
  }

  public func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    try await mock.joinClass(joinCode: joinCode, nickname: nickname)
  }
}
