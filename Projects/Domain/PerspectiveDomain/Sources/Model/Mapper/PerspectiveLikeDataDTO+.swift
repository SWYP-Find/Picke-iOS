//
//  PerspectiveLikeDataDTO+.swift
//  PerspectiveDomain
//
//  Created by Picke on 10/11/26.
//

import Foundation

import CommentDomainInterface

public extension PerspectiveLikeDataDTO {
  func toDomain() -> CommentLikeResult {
    CommentLikeResult(
      perspectiveId: perspectiveId,
      likeCount: likeCount,
      isLiked: isLiked ?? false
    )
  }
}
