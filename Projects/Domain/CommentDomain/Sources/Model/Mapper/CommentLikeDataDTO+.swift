//
//  CommentLikeDataDTO+.swift
//  CommentDomain
//

import CommentDomainInterface
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
