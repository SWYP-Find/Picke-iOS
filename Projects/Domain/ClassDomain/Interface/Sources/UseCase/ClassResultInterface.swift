import ComposableArchitecture

public protocol ClassResultInterface: Sendable {
  func fetch(roomID: Int) async throws -> ClassResult
  func fetchPersonal(roomID: Int) async throws -> ClassAIPersonalFeedback
  func fetchInsight(roomID: Int) async throws -> ClassAIInsight
  func retryInsight(roomID: Int) async throws
}

public enum ClassResultUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassResultInterface {
    UnimplementedClassResultUseCase()
  }
}

public enum ClassResultRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassResultInterface {
    UnimplementedClassResultUseCase()
  }
}

public extension DependencyValues {
  var classResultRepository: any ClassResultInterface {
    get { self[ClassResultRepositoryDependency.self] }
    set { self[ClassResultRepositoryDependency.self] = newValue }
  }

  var classResultUseCase: any ClassResultInterface {
    get { self[ClassResultUseCaseDependency.self] }
    set { self[ClassResultUseCaseDependency.self] = newValue }
  }
}

private struct UnimplementedClassResultUseCase: ClassResultInterface {
  func fetch(roomID _: Int) async throws -> ClassResult {
    throw ClassError.network("클래스 결과 API가 연결되지 않았습니다.")
  }

  func fetchPersonal(roomID _: Int) async throws -> ClassAIPersonalFeedback {
    throw ClassAIFeedbackError.temporarilyUnavailable
  }

  func fetchInsight(roomID _: Int) async throws -> ClassAIInsight {
    throw ClassAIFeedbackError.temporarilyUnavailable
  }

  func retryInsight(roomID _: Int) async throws {
    throw ClassAIFeedbackError.temporarilyUnavailable
  }
}
