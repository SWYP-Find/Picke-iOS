import ComposableArchitecture
import Foundation

public protocol ClassAIRepositoryInterface: Sendable {
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

public enum ClassAIRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassAIRepositoryInterface {
    UnimplementedClassAIRepository()
  }
}

public extension DependencyValues {
  var classAIRepository: any ClassAIRepositoryInterface {
    get { self[ClassAIRepositoryDependency.self] }
    set { self[ClassAIRepositoryDependency.self] = newValue }
  }
}

private struct UnimplementedClassAIRepository: ClassAIRepositoryInterface {
  func fetchDebate(classID _: Int) async throws -> ClassDebate {
    throw ClassAIChatError.noSession
  }

  func startDebate(classID _: Int) async throws -> ClassDebate {
    throw ClassAIChatError.noSession
  }

  func submitDebateReply(
    classID _: Int,
    round _: Int,
    content _: String,
    requestKey _: UUID
  ) async throws -> ClassDebate {
    throw ClassAIChatError.noSession
  }

  func retryDebate(classID _: Int) async throws -> ClassDebate {
    throw ClassAIChatError.noSession
  }

}
