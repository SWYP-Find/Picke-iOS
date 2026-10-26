import ComposableArchitecture
import Foundation

public protocol ClassTopicDraftInterface: Sendable {
  func create(filter: ClassTopicFilter) async throws -> ClassTopicDraft
  func fetch(id: Int) async throws -> ClassTopicDraft
  func suggest(
    id: Int,
    filter: ClassTopicFilter?
  ) async throws -> ClassTopicDraft
  func select(
    draftID: Int,
    batchNo: Int,
    candidateID: Int
  ) async throws -> ClassTopicVersion
  func validate(
    draftID: Int,
    baseVersionID: Int,
    candidate: ClassTopicCandidate
  ) async throws -> ClassTopicValidation
}

public enum ClassTopicDraftRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassTopicDraftInterface { UnimplementedClassTopicDraft() }
}

public enum ClassTopicDraftUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassTopicDraftInterface { UnimplementedClassTopicDraft() }
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

private struct UnimplementedClassTopicDraft: ClassTopicDraftInterface {
  func create(filter: ClassTopicFilter) async throws -> ClassTopicDraft { throw ClassError.unknown("주제 초안 미설정") }
  func fetch(id: Int) async throws -> ClassTopicDraft { throw ClassError.unknown("주제 초안 미설정") }
  func suggest(
    id: Int,
    filter: ClassTopicFilter?
  ) async throws -> ClassTopicDraft { throw ClassError.unknown("주제 초안 미설정") }

  func select(
    draftID: Int,
    batchNo: Int,
    candidateID: Int
  ) async throws -> ClassTopicVersion { throw ClassError.unknown("주제 초안 미설정") }

  func validate(
    draftID: Int,
    baseVersionID: Int,
    candidate: ClassTopicCandidate
  ) async throws -> ClassTopicValidation { throw ClassError.unknown("주제 초안 미설정") }
}
