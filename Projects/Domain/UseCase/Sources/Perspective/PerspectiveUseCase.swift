//
//  PerspectiveUseCase.swift
//  UseCase
//

import Foundation

import DomainInterface
import Entity

import ComposableArchitecture

public struct PerspectiveUseCaseImpl: PerspectiveInterface {
  @Dependency(\.perspectiveRepository) private var perspectiveRepository

  public init() {}

  public func fetchPerspective(perspectiveId: Int) async throws -> BattlePerspective {
    return try await perspectiveRepository.fetchPerspective(perspectiveId: perspectiveId)
  }

  public func fetchLabeledComments(
    perspectiveId: Int,
    cursor: String?,
    size: Int?
  ) async throws -> PerspectiveCommentPage {
    return try await perspectiveRepository.fetchLabeledComments(
      perspectiveId: perspectiveId,
      cursor: cursor,
      size: size
    )
  }

  public func createComment(
    perspectiveId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    return try await perspectiveRepository.createComment(perspectiveId: perspectiveId, content: content)
  }

  public func updateComment(
    perspectiveId: Int,
    commentId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    return try await perspectiveRepository.updateComment(
      perspectiveId: perspectiveId,
      commentId: commentId,
      content: content
    )
  }

  public func deleteComment(
    perspectiveId: Int,
    commentId: Int
  ) async throws {
    return try await perspectiveRepository.deleteComment(perspectiveId: perspectiveId, commentId: commentId)
  }

  public func updatePerspective(perspectiveId: Int, content: String) async throws {
    return try await perspectiveRepository.updatePerspective(perspectiveId: perspectiveId, content: content)
  }

  public func deletePerspective(perspectiveId: Int) async throws {
    return try await perspectiveRepository.deletePerspective(perspectiveId: perspectiveId)
  }

  public func likePerspective(perspectiveId: Int) async throws -> CommentLikeResult {
    return try await perspectiveRepository.likePerspective(perspectiveId: perspectiveId)
  }

  public func unlikePerspective(perspectiveId: Int) async throws -> CommentLikeResult {
    return try await perspectiveRepository.unlikePerspective(perspectiveId: perspectiveId)
  }

  public func fetchPerspectiveLikes(perspectiveId: Int) async throws -> CommentLikeResult {
    return try await perspectiveRepository.fetchPerspectiveLikes(perspectiveId: perspectiveId)
  }
}

extension PerspectiveUseCaseImpl: DependencyKey {
  public static var liveValue = PerspectiveUseCaseImpl()
  public static var testValue = PerspectiveUseCaseImpl()
  public static var previewValue = PerspectiveUseCaseImpl()
}

public extension DependencyValues {
  var perspectiveUseCase: PerspectiveUseCaseImpl {
    get { self[PerspectiveUseCaseImpl.self] }
    set { self[PerspectiveUseCaseImpl.self] = newValue }
  }
}
