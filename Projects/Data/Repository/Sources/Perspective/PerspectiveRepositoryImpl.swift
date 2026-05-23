//
//  PerspectiveRepositoryImpl.swift
//  Repository
//

import Foundation

import DomainInterface
import Entity
import Model
import Service

import LogMacro
import Moya

@preconcurrency import AsyncMoya

public final class PerspectiveRepositoryImpl: PerspectiveInterface, @unchecked Sendable {
  private let provider: MoyaProvider<PerspectiveService>

  public init(
    provider: MoyaProvider<PerspectiveService> = MoyaProvider<PerspectiveService>.authorized
  ) {
    self.provider = provider
  }

  public func fetchPerspective(perspectiveId: Int) async throws -> BattlePerspective {
    let dto: PerspectiveDetailResponseDTO = try await provider.request(
      .detail(perspectiveId: perspectiveId)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "perspective 상세 응답이 비어 있습니다"
      Log.error("[PerspectiveRepositoryImpl] empty detail payload: \(message)")
      throw PerspectiveError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchLabeledComments(
    perspectiveId: Int,
    cursor: String?,
    size: Int?
  ) async throws -> PerspectiveCommentPage {
    let dto: PerspectiveCommentPageResponseDTO = try await provider.request(
      .listLabeledComments(perspectiveId: perspectiveId, cursor: cursor, size: size)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "대댓글 목록 응답이 비어 있습니다"
      Log.error("[PerspectiveRepositoryImpl] empty list payload: \(message)")
      throw CommentError.backendError(message)
    }

    return data.toDomain()
  }

  public func createComment(
    perspectiveId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    let dto: PerspectiveCommentMutationResponseDTO = try await provider.request(
      .createComment(perspectiveId: perspectiveId, body: PerspectiveCommentBody(content: content))
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "대댓글 작성 응답이 비어 있습니다"
      Log.error("[PerspectiveRepositoryImpl] empty create payload: \(message)")
      throw CommentError.backendError(message)
    }

    return data.toDomain()
  }

  public func updateComment(
    perspectiveId: Int,
    commentId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    let dto: PerspectiveCommentMutationResponseDTO = try await provider.request(
      .updateComment(
        perspectiveId: perspectiveId,
        commentId: commentId,
        body: PerspectiveCommentBody(content: content)
      )
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "대댓글 수정 응답이 비어 있습니다"
      Log.error("[PerspectiveRepositoryImpl] empty update payload: \(message)")
      throw CommentError.backendError(message)
    }

    return data.toDomain()
  }

  public func deleteComment(
    perspectiveId: Int,
    commentId: Int
  ) async throws {
    let dto: BaseResponseDTO<EmptyDTO> = try await provider.request(
      .deleteComment(perspectiveId: perspectiveId, commentId: commentId)
    )

    if dto.statusCode >= 400 {
      let message = dto.error?.message ?? "대댓글 삭제 실패"
      throw CommentError.backendError(message)
    }
  }

  public func deletePerspective(perspectiveId: Int) async throws {
    let dto: BaseResponseDTO<String> = try await provider.request(
      .deletePerspective(perspectiveId: perspectiveId)
    )

    if dto.statusCode >= 400 {
      let message = dto.error?.message ?? "perspective 삭제 실패"
      throw PerspectiveError.backendError(message)
    }
  }
}

public struct EmptyDTO: Decodable {}
