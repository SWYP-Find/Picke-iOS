//
//  PerspectiveLikeDataDTO+.swift
//  PerspectiveDomain
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
