//
//  CommentLikeDataDTO+.swift
//  CommentDomain
//
//  Created by Picke on 10/11/26.
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
