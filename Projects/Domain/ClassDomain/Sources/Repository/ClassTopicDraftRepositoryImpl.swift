import ClassDomainInterface
import Dependencies
import Foundation
import PickeNetwork

public struct ClassTopicDraftRepositoryImpl: ClassTopicDraftInterface {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func create(filter: ClassTopicFilter) async throws -> ClassTopicDraft {
    try await send(ClassTopicDraftService.create(filter), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func fetch(id: Int) async throws -> ClassTopicDraft {
    try await send(ClassTopicDraftService.detail(id), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func suggest(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft {
    try await send(ClassTopicDraftService.suggest(id, filter), as: ClassTopicDraftDTO.self).toDomain()
  }

  public func select(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion {
    try await send(
      ClassTopicDraftService.select(draftID: draftID, batchNo: batchNo, candidateID: candidateID),
      as: ClassTopicVersionDTO.self
    ).toDomain()
  }

  public func validate(draftID: Int, baseVersionID: Int, candidate: ClassTopicCandidate) async throws -> ClassTopicValidation {
    try await send(
      ClassTopicDraftService.validate(draftID: draftID, baseVersionID: baseVersionID, candidate: candidate),
      as: ClassTopicValidationDTO.self
    ).toDomain()
  }

  private func send<T: Decodable & Sendable>(
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
