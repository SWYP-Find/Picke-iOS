//
//  ClassUseCaseImpl+TopicDraft.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func createTopicDraft(filter: ClassTopicFilter) async throws -> ClassTopicDraft {
    try await repository.createTopicDraft(filter: filter)
  }

  public func fetchTopicDraft(id: Int) async throws -> ClassTopicDraft {
    try await repository.fetchTopicDraft(id: id)
  }

  public func suggestTopicDraft(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft {
    try await repository.suggestTopicDraft(id: id, filter: filter)
  }

  public func selectTopicDraft(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion {
    try await repository.selectTopicDraft(draftID: draftID, batchNo: batchNo, candidateID: candidateID)
  }

  public func validateTopicDraft(
    draftID: Int,
    baseVersionID: Int,
    candidate: ClassTopicCandidate
  ) async throws -> ClassTopicValidation {
    try await repository.validateTopicDraft(
      draftID: draftID,
      baseVersionID: baseVersionID,
      candidate: candidate
    )
  }
}
