import ComposableArchitecture
import Foundation

public protocol ClassDebateInterface: Sendable {
  func fetch(classID: Int) async throws -> ClassDebate
  func start(classID: Int) async throws -> ClassDebate
  func submitReply(classID: Int, round: Int, content: String, requestKey: UUID) async throws -> ClassDebate
  func retry(classID: Int) async throws -> ClassDebate
}

public enum ClassDebateUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassDebateInterface {
    UnimplementedClassDebateUseCase()
  }
}

public extension DependencyValues {
  var classDebateUseCase: any ClassDebateInterface {
    get { self[ClassDebateUseCaseDependency.self] }
    set { self[ClassDebateUseCaseDependency.self] = newValue }
  }
}

private struct UnimplementedClassDebateUseCase: ClassDebateInterface {
  func fetch(classID _: Int) async throws -> ClassDebate {
    throw ClassAIChatError.unavailable
  }

  func start(classID _: Int) async throws -> ClassDebate {
    throw ClassAIChatError.unavailable
  }

  func submitReply(classID _: Int, round _: Int, content _: String, requestKey _: UUID) async throws -> ClassDebate {
    throw ClassAIChatError.unavailable
  }

  func retry(classID _: Int) async throws -> ClassDebate {
    throw ClassAIChatError.unavailable
  }
}
