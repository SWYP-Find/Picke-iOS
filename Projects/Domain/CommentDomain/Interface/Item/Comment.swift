//
//  Comment.swift
//  Entity
//

import Foundation

public struct Comment: Equatable, Identifiable, Hashable {
  public let id: Int
  public let author: CommentAuthor
  public let text: String
  public let createdAt: Date
  public let likeCount: Int
  public let replyCount: Int
  public let isLiked: Bool

  public init(
    id: Int,
    author: CommentAuthor,
    text: String,
    createdAt: Date,
    likeCount: Int,
    replyCount: Int,
    isLiked: Bool
  ) {
    self.id = id
    self.author = author
    self.text = text
    self.createdAt = createdAt
    self.likeCount = likeCount
    self.replyCount = replyCount
    self.isLiked = isLiked
  }
}
