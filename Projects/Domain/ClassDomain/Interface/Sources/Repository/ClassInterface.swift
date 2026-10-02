import ComposableArchitecture
import Foundation

public protocol ClassInterface: Sendable {
  func fetchMyClasses() async throws -> [ClassRoom]
  func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary]
  func createClass(_ creation: ClassCreation) async throws -> ClassRoom
  func fetchClass(joinCode: String) async throws -> ClassRoom
  func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom
  func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom
  func deleteClass(id: Int) async throws
}

public enum ClassRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassInterface {
    MockClassRepository()
  }
}

public enum ClassUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classRepository: any ClassInterface {
    get { self[ClassRepositoryDependency.self] }
    set { self[ClassRepositoryDependency.self] = newValue }
  }

  var classUseCase: any ClassInterface {
    get { self[ClassUseCaseDependency.self] }
    set { self[ClassUseCaseDependency.self] = newValue }
  }
}
