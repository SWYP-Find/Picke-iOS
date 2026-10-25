import ClassDomainInterface
import ComposableArchitecture
import Foundation

public struct ClassTopicDraftUseCaseImpl: ClassTopicDraftInterface {
  @Dependency(\.classTopicDraftRepository) private var repository

  public init() {}

  public func create(filter: ClassTopicFilter) async throws -> ClassTopicDraft {
    try await repository.create(filter: filter)
  }

  public func fetch(id: Int) async throws -> ClassTopicDraft {
    try await repository.fetch(id: id)
  }

  public func suggest(
    id: Int,
    filter: ClassTopicFilter?
  ) async throws -> ClassTopicDraft {
    try await repository.suggest(id: id, filter: filter)
  }

  public func select(
    draftID: Int,
    batchNo: Int,
    candidateID: Int
  ) async throws -> ClassTopicVersion {
    try await repository.select(draftID: draftID, batchNo: batchNo, candidateID: candidateID)
  }

  public func validate(
    draftID: Int,
    baseVersionID: Int,
    candidate: ClassTopicCandidate
  ) async throws -> ClassTopicValidation {
    try await repository.validate(draftID: draftID, baseVersionID: baseVersionID, candidate: candidate)
  }
}
