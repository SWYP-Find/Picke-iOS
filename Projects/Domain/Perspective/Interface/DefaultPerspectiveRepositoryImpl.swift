//
//  DefaultPerspectiveRepositoryImpl.swift
//  PerspectiveDomainInterface
//
//  Created by Wonji Suh  on 6/3/26.
//

import CommentDomainInterface
import CommonDomainInterface
import Foundation

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

  public func deleteComment(
    perspectiveId _: Int,
    commentId _: Int
  ) async throws {}

  public func updatePerspective(perspectiveId _: Int, content _: String) async throws {}

  public func deletePerspective(perspectiveId _: Int) async throws {}

  public func likePerspective(perspectiveId: Int) async throws -> CommentLikeResult {
    CommentLikeResult(perspectiveId: perspectiveId, likeCount: 0, isLiked: true)
  }

  public func unlikePerspective(perspectiveId: Int) async throws -> CommentLikeResult {
    CommentLikeResult(perspectiveId: perspectiveId, likeCount: 0, isLiked: false)
  }

  public func fetchPerspectiveLikes(perspectiveId: Int) async throws -> CommentLikeResult {
    CommentLikeResult(perspectiveId: perspectiveId, likeCount: 0, isLiked: false)
  }

  public func reportPerspective(perspectiveId _: Int) async throws {}

  public func reportComment(perspectiveId _: Int, commentId _: Int) async throws {}
}
