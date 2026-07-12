//
//  PerspectiveComment.swift
//  Entity
//
//  `GET /api/v1/perspectives/{perspectiveId}/comments/labeled` 등 대댓글 API 도메인 모델.
//

import Foundation

public struct PerspectiveComment: Equatable, Identifiable, Hashable {
  public let commentId: Int
  public let user: PerspectiveCommentUser
  public let stance: String
  public let content: String
  public let likeCount: Int
  public let isLiked: Bool
  public let isMine: Bool
  public let createdAt: Date?

  public var id: Int { commentId }

  public init(
    commentId: Int,
    user: PerspectiveCommentUser,
    stance: String,
    content: String,
    likeCount: Int,
    isLiked: Bool,
    isMine: Bool,
    createdAt: Date?
  ) {
    self.commentId = commentId
    self.user = user
    self.stance = stance
    self.content = content
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.isMine = isMine
    self.createdAt = createdAt
  }
}
