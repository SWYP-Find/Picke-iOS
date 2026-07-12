//
//  CommentLikeDataDTO+.swift
//  Model
//

import CommonDomainInterface
import Entity
import Foundation

public extension CommentLikeDataDTO {
  func toDomain() -> CommentLikeResult {
    CommentLikeResult(
      perspectiveId: perspectiveId,
      likeCount: likeCount,
      isLiked: isLiked ?? false
    )
  }
}
