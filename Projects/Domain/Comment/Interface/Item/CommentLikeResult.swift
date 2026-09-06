//
//  CommentLikeResult.swift
//  CommentDomainInterface
//

import Foundation

public struct CommentLikeResult: Equatable, Hashable {
  public let perspectiveId: Int
  public let likeCount: Int
  public let isLiked: Bool

  public init(
    perspectiveId: Int,
    likeCount: Int,
    isLiked: Bool
  ) {
    self.perspectiveId = perspectiveId
    self.likeCount = likeCount
    self.isLiked = isLiked
  }
}
