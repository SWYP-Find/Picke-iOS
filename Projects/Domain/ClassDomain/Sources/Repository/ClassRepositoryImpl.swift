import ClassDomainInterface
import Foundation

public struct ClassRepositoryImpl: ClassInterface {
  private static let unavailableMessage = "클래스 서버 API가 연결되지 않았습니다."

  public init() {}

  public func fetchMyClasses() async throws -> [ClassRoom] {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func fetchRecommendedBattles(filter _: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func createClass(_: ClassCreation) async throws -> ClassRoom {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func fetchClass(joinCode _: String) async throws -> ClassRoom {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func joinClass(joinCode _: String, nickname _: String) async throws -> ClassRoom {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func updateDeadline(id _: Int, deadline _: Date) async throws -> ClassRoom {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func deleteClass(id _: Int) async throws {
    throw ClassError.network(Self.unavailableMessage)
  }
}
