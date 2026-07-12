//
//  CommentRepositoryImpl.swift
//  Repository
//

import Foundation

import CommentDomainInterface
import CommonDomainInterface
import Model
import Repository

import LogMacro
import Moya

@preconcurrency import AsyncMoya

public final class CommentRepositoryImpl: CommentInterface, @unchecked Sendable {
  private let provider: MoyaProvider<CommentService>

  public init(
    provider: MoyaProvider<CommentService> = MoyaProvider<CommentService>.authorized
  ) {
    self.provider = provider
  }

  public func likeComment(commentId: Int) async throws -> CommentLikeResult {
    let dto: CommentLikeResponseDTO = try await provider.request(.like(commentId: commentId))

    guard let data = dto.data else {
      let message = dto.error?.message ?? "댓글 좋아요 응답이 비어 있습니다"
      Log.error("[CommentRepositoryImpl] empty like payload: \(message)")
      throw CommentError.backendError(message)
    }

    return data.toDomain()
  }

  public func unlikeComment(commentId: Int) async throws -> CommentLikeResult {
    let dto: CommentLikeResponseDTO = try await provider.request(.unlike(commentId: commentId))

    guard let data = dto.data else {
      let message = dto.error?.message ?? "댓글 좋아요 취소 응답이 비어 있습니다"
      Log.error("[CommentRepositoryImpl] empty unlike payload: \(message)")
      throw CommentError.backendError(message)
    }

    return data.toDomain()
  }
}
