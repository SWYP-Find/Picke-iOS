import ComposableArchitecture
import Foundation

public protocol ClassDebateInterface: Sendable {
  func fetchDebate(classID: Int) async throws -> ClassDebate
  func startDebate(classID: Int) async throws -> ClassDebate
  func submitDebateReply(
    classID: Int,
    round: Int,
    content: String,
    requestKey: UUID
  ) async throws -> ClassDebate
  func retryDebate(classID: Int) async throws -> ClassDebate
}

public enum ClassDebateRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassDebateInterface {
    MockClassRepository()
  }
}

public enum ClassDebateUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassDebateInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classDebateRepository: any ClassDebateInterface {
    get { self[ClassDebateRepositoryDependency.self] }
    set { self[ClassDebateRepositoryDependency.self] = newValue }
  }

  var classDebateUseCase: any ClassDebateInterface {
    get { self[ClassDebateUseCaseDependency.self] }
    set { self[ClassDebateUseCaseDependency.self] = newValue }
  }
}
