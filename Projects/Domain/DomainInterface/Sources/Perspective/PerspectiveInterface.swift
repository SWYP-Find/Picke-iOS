//
//  PerspectiveInterface.swift
//  DomainInterface
//

import Dependencies
import Entity
import Foundation
import WeaveDI

public protocol PerspectiveInterface: Sendable {
  func fetchPerspective(perspectiveId: Int) async throws -> BattlePerspective
  func fetchLabeledComments(
    perspectiveId: Int,
    cursor: String?,
    size: Int?
  ) async throws -> PerspectiveCommentPage
  func createComment(
    perspectiveId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult
  func updateComment(
    perspectiveId: Int,
    commentId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult
  func deleteComment(perspectiveId: Int, commentId: Int) async throws
}

public struct DefaultPerspectiveRepositoryImpl: PerspectiveInterface {
  public init() {}

  public func fetchPerspective(perspectiveId: Int) async throws -> BattlePerspective {
    BattlePerspective(
      perspectiveId: perspectiveId,
      user: BattlePerspectiveUser(userTag: "", nickname: "", characterType: "", characterImageUrl: nil),
      option: BattlePerspectiveOption(optionId: 0, label: nil, title: "", stance: ""),
      content: "",
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
      isMyPerspective: false,
      createdAt: nil
    )
  }

  public func fetchLabeledComments(
    perspectiveId _: Int,
    cursor _: String?,
    size _: Int?
  ) async throws -> PerspectiveCommentPage {
    PerspectiveCommentPage(items: [], nextCursor: nil, hasNext: false)
  }

  public func createComment(
    perspectiveId _: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    PerspectiveCommentMutationResult(commentId: 0, content: content, updatedAt: nil)
  }

  public func updateComment(
    perspectiveId _: Int,
    commentId: Int,
    content: String
  ) async throws -> PerspectiveCommentMutationResult {
    PerspectiveCommentMutationResult(commentId: commentId, content: content, updatedAt: nil)
  }

  public func deleteComment(perspectiveId _: Int, commentId _: Int) async throws {}
}

public struct PerspectiveRepositoryDependency: DependencyKey {
  public static var liveValue: PerspectiveInterface {
    UnifiedDI.resolve(PerspectiveInterface.self) ?? DefaultPerspectiveRepositoryImpl()
  }

  public static var testValue: PerspectiveInterface {
    UnifiedDI.resolve(PerspectiveInterface.self) ?? DefaultPerspectiveRepositoryImpl()
  }

  public static var previewValue: PerspectiveInterface = liveValue
}

public extension DependencyValues {
  var perspectiveRepository: PerspectiveInterface {
    get { self[PerspectiveRepositoryDependency.self] }
    set { self[PerspectiveRepositoryDependency.self] = newValue }
  }
}
