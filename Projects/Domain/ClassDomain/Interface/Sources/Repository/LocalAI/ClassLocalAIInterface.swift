import ComposableArchitecture
import Foundation

public protocol ClassLocalAIInterface: Sendable {
  func startAIChat(_ id: UUID, _ context: ClassAIChatContext) async throws
  func respondAIChat(_ id: UUID, _ text: String, isFinalRound: Bool) async throws -> String
  func endAIChat(_ id: UUID) async
  func generateAIFeedback(context: ClassAIFeedbackContext) async throws -> ClassAIFeedbackResult
}

public enum ClassLocalAIRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassLocalAIInterface {
    MockClassRepository()
  }
}

public enum ClassLocalAIUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassLocalAIInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classLocalAIRepository: any ClassLocalAIInterface {
    get { self[ClassLocalAIRepositoryDependency.self] }
    set { self[ClassLocalAIRepositoryDependency.self] = newValue }
  }

  var classLocalAIUseCase: any ClassLocalAIInterface {
    get { self[ClassLocalAIUseCaseDependency.self] }
    set { self[ClassLocalAIUseCaseDependency.self] = newValue }
  }
}
