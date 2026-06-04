//
//  PerspectiveComment.swift
//  Entity
//
//  `GET /api/v1/perspectives/{perspectiveId}/comments/labeled` 등 대댓글 API 도메인 모델.
//

import Foundation

public struct PerspectiveCommentPage: Equatable {
  public let items: [PerspectiveComment]
  public let nextCursor: String?
  public let hasNext: Bool

  public init(
    items: [PerspectiveComment],
    nextCursor: String?,
    hasNext: Bool
  ) {
    self.items = items
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }
}

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

public struct PerspectiveCommentUser: Equatable, Hashable {
  public let userTag: String
  public let nickname: String
  public let characterType: String
  public let characterImageUrl: String?

  public init(
    userTag: String,
    nickname: String,
    characterType: String,
    characterImageUrl: String?
  ) {
    self.userTag = userTag
    self.nickname = nickname
    self.characterType = characterType
    self.characterImageUrl = characterImageUrl
  }
}

/// 대댓글 작성/수정 응답.
public struct PerspectiveCommentMutationResult: Equatable, Hashable {
  public let commentId: Int
  public let content: String
  public let updatedAt: Date?

  public init(
    commentId: Int,
    content: String,
    updatedAt: Date?
  ) {
    self.commentId = commentId
    self.content = content
    self.updatedAt = updatedAt
  }
}
