import ComposableArchitecture
import Foundation

public protocol ClassAIChatInterface: Sendable {
  func start(_ id: UUID, _ context: ClassAIChatContext) async throws
  func respond(_ id: UUID, _ text: String) async throws -> String
  func end(_ id: UUID) async
}

public enum ClassAIChatUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassAIChatInterface {
    MockClassAIChatUseCase()
  }

  public static var previewValue: any ClassAIChatInterface {
    MockClassAIChatUseCase()
  }
}

public extension DependencyValues {
  var classAIChatUseCase: any ClassAIChatInterface {
    get { self[ClassAIChatUseCaseDependency.self] }
    set { self[ClassAIChatUseCaseDependency.self] = newValue }
  }
}
