//
//  PerspectiveCommentDataDTO+.swift
//  Model
//

import Entity
import Foundation

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
      createdAt: createdAt.flatMap(Self.parseISO8601)
    )
  }

  private static func parseISO8601(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value)
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
      updatedAt: updatedAt.flatMap(Self.parseISO8601)
    )
  }

  private static func parseISO8601(_ value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value)
  }
}
