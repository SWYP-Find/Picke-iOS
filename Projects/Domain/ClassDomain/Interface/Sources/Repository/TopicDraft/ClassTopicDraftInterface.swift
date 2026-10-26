import ComposableArchitecture
import Foundation

public protocol ClassTopicDraftInterface: Sendable {
  func createTopicDraft(filter: ClassTopicFilter) async throws -> ClassTopicDraft
  func fetchTopicDraft(id: Int) async throws -> ClassTopicDraft
  func suggestTopicDraft(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft
  func selectTopicDraft(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion
  func validateTopicDraft(
    draftID: Int,
    baseVersionID: Int,
    candidate: ClassTopicCandidate
  ) async throws -> ClassTopicValidation
}

public enum ClassTopicDraftRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassTopicDraftInterface {
    MockClassRepository()
  }
}

public enum ClassTopicDraftUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassTopicDraftInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classTopicDraftRepository: any ClassTopicDraftInterface {
    get { self[ClassTopicDraftRepositoryDependency.self] }
    set { self[ClassTopicDraftRepositoryDependency.self] = newValue }
  }

  var classTopicDraftUseCase: any ClassTopicDraftInterface {
    get { self[ClassTopicDraftUseCaseDependency.self] }
    set { self[ClassTopicDraftUseCaseDependency.self] = newValue }
  }
}
