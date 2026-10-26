//
//  ClassRepositoryImpl+TopicDraft.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork

extension ClassRepositoryImpl {
  public func createTopicDraft(filter: ClassTopicFilter) async throws -> ClassTopicDraft {
    try await sendTopicDraft(ClassTopicDraftService.create(filter), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func fetchTopicDraft(id: Int) async throws -> ClassTopicDraft {
    try await sendTopicDraft(ClassTopicDraftService.detail(id), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func suggestTopicDraft(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft {
    try await sendTopicDraft(ClassTopicDraftService.suggest(id, filter), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func selectTopicDraft(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion {
    try await sendTopicDraft(
      ClassTopicDraftService.select(draftID: draftID, batchNo: batchNo, candidateID: candidateID),
      as: ClassTopicVersionDTO.self
    ).toDomain()
  }

  public func validateTopicDraft(draftID: Int, baseVersionID: Int, candidate: ClassTopicCandidate) async throws -> ClassTopicValidation {
    try await sendTopicDraft(
      ClassTopicDraftService.validate(draftID: draftID, baseVersionID: baseVersionID, candidate: candidate),
      as: ClassTopicValidationDTO.self
    ).toDomain()
  }

  private func sendTopicDraft<T: Decodable & Sendable>(
    _ request: some PickeDataRequest,
    as type: T.Type
  ) async throws -> T {
    do {
      return try await client.send(request, as: type)
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        throw ClassError.network(response.message ?? "AI 주제 요청을 처리하지 못했어요.")
      }
      throw ClassError.from(error)
    } catch {
      throw ClassError.from(error)
    }
  }
}
