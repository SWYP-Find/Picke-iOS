//
//  PerspectiveCommentDataDTO+.swift
//  PerspectiveDomain
//

import CommentDomainInterface
import Foundation

import PickeCoreUtility

public extension PerspectiveCommentPageDataDTO {
  func toDomain() -> PerspectiveCommentPage {
    PerspectiveCommentPage(
      items: items.map { $0.toDomain() },
      nextCursor: nextCursor,
      hasNext: hasNext
    )
  }
}

public extension PerspectiveCommentDTO {
  func toDomain() -> PerspectiveComment {
    PerspectiveComment(
      commentId: commentId,
      user: user.toDomain(),
      stance: stance ?? "",
      content: content,
      likeCount: likeCount,
      isLiked: isLiked ?? false,
      isMine: isMine ?? false,
      createdAt: createdAt.flatMap(ServerDateParser.parse)
    )
  }
}

public extension PerspectiveCommentUserDTO {
  func toDomain() -> PerspectiveCommentUser {
    PerspectiveCommentUser(
      userTag: userTag ?? "",
      nickname: nickname ?? "익명",
      characterType: characterType ?? "",
      characterImageUrl: characterImageUrl
    )
  }
}

public extension PerspectiveCommentMutationDataDTO {
  func toDomain() -> PerspectiveCommentMutationResult {
    PerspectiveCommentMutationResult(
      commentId: commentId,
      content: content,
      updatedAt: updatedAt.flatMap(ServerDateParser.parse)
    )
  }
}
