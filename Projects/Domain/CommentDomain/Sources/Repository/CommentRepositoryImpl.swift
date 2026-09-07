//
//  CommentRepositoryImpl.swift
//  Repository
//

import Foundation

import Dependencies

import APIEndpoint
import CommentDomainInterface
import PickeNetwork

import LogMacro

public final class CommentRepositoryImpl: CommentInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func likeComment(commentId: Int) async throws -> CommentLikeResult {
    let data = try await client.send(
      CommentService.like(commentId: commentId),
      as: CommentLikeDataDTO.self
    )

    return data.toDomain()
  }

  public func unlikeComment(commentId: Int) async throws -> CommentLikeResult {
    let data = try await client.send(
      CommentService.unlike(commentId: commentId),
      as: CommentLikeDataDTO.self
    )

    return data.toDomain()
  }
}
