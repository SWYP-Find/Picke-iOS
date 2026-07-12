//
//  PerspectiveCommentMutationResult.swift
//  Entity
//

import Foundation

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
