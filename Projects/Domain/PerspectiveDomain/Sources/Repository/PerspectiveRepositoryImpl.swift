//
//  PerspectiveRepositoryImpl.swift
//  Repository
//

import Foundation

import Dependencies

import APIEndpoint
import BattleDomainInterface
import CommentDomainInterface
import PickeNetwork
import PerspectiveDomainInterface

import LogMacro

public final class PerspectiveRepositoryImpl: PerspectiveInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchPerspective(perspectiveId: Int) async throws -> BattlePerspective {
    let data = try await client.send(
      PerspectiveService.detail(perspectiveId: perspectiveId),
      as: PerspectiveDetailDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchLabeledComments(
    perspectiveId: Int,
    cursor: String?,
    size: Int?
  ) async throws -> PerspectiveCommentPage {
    let data = try await client.send(
      PerspectiveService.listLabeledComments(perspectiveId: perspectiveId, cursor: cursor, size: size),
      as: PerspectiveCommentPageDataDTO.self
    )

    return data.toDomain()
  }

  public func createComment(
    perspectiveId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    let data = try await client.send(
      PerspectiveService.createComment(perspectiveId: perspectiveId, body: PerspectiveCommentBody(content: content)),
      as: PerspectiveCommentMutationDataDTO.self
    )

    return data.toDomain()
  }

  public func updateComment(
    perspectiveId: Int,
    commentId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    let data = try await client.send(
      PerspectiveService.updateComment( perspectiveId: perspectiveId, commentId: commentId, body: PerspectiveCommentBody(content: content) ),
      as: PerspectiveCommentMutationDataDTO.self
    )

    return data.toDomain()
  }

  public func deleteComment(
    perspectiveId: Int,
    commentId: Int
  ) async throws {
    _ = try await client.send(
      PerspectiveService.deleteComment(perspectiveId: perspectiveId, commentId: commentId),
      as: PickeEmptyResponse.self
    )
  }

  public func updatePerspective(perspectiveId: Int, content: String) async throws {
    _ = try await client.send(
      PerspectiveService.updatePerspective(perspectiveId: perspectiveId, body: PerspectiveCommentBody(content: content)),
      as: PickeEmptyResponse.self
    )
  }

  public func deletePerspective(perspectiveId: Int) async throws {
    _ = try await client.send(
      PerspectiveService.deletePerspective(perspectiveId: perspectiveId),
      as: PickeEmptyResponse.self
    )
  }

  public func likePerspective(perspectiveId: Int) async throws -> CommentLikeResult {
    let data = try await client.send(
      PerspectiveService.likePerspective(perspectiveId: perspectiveId),
      as: PerspectiveLikeDataDTO.self
    )

    return CommentLikeResult(perspectiveId: data.perspectiveId, likeCount: data.likeCount, isLiked: true)
  }

  public func unlikePerspective(perspectiveId: Int) async throws -> CommentLikeResult {
    let data = try await client.send(
      PerspectiveService.unlikePerspective(perspectiveId: perspectiveId),
      as: PerspectiveLikeDataDTO.self
    )

    return CommentLikeResult(perspectiveId: data.perspectiveId, likeCount: data.likeCount, isLiked: false)
  }

  public func fetchPerspectiveLikes(perspectiveId: Int) async throws -> CommentLikeResult {
    let data = try await client.send(
      PerspectiveService.fetchPerspectiveLikes(perspectiveId: perspectiveId),
      as: PerspectiveLikeDataDTO.self
    )

    return data.toDomain()
  }

  public func reportPerspective(perspectiveId: Int) async throws {
    _ = try await client.send(
      PerspectiveService.reportPerspective(perspectiveId: perspectiveId),
      as: PickeEmptyResponse.self
    )
  }

  public func reportComment(perspectiveId: Int, commentId: Int) async throws {
    _ = try await client.send(
      PerspectiveService.reportComment(perspectiveId: perspectiveId, commentId: commentId),
      as: PickeEmptyResponse.self
    )
  }
}
