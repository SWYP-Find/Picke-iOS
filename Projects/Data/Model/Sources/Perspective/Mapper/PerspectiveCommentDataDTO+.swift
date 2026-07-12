//
//  PerspectiveCommentDataDTO+.swift
//  Model
//

import CommentDomainInterface
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
      createdAt: createdAt.flatMap(PerspectiveDateParser.parse)
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
      updatedAt: updatedAt.flatMap(PerspectiveDateParser.parse)
    )
  }
}

/// 관점/댓글 서버 시간 문자열 파서.
/// 서버가 `2026-05-22T13:28:16.697Z`(타임존 포함) 또는
/// `2026-05-22T13:28:16`(타임존 없는 LocalDateTime) 양쪽 모두 보낼 수 있어
/// ISO8601 우선 시도 후 타임존 없는 포맷까지 폴백한다.
/// (기존엔 타임존 없는 문자열이 nil 로 파싱돼 모든 댓글이 "방금 전"으로 표시되던 버그)
enum PerspectiveDateParser {
  static func parse(_ value: String) -> Date? {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = isoFormatter.date(from: value) { return date }
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let date = isoFormatter.date(from: value) { return date }

    // 타임존이 없는 LocalDateTime 폴백 — 서버 기준시(KST)로 해석.
    let fallback = DateFormatter()
    fallback.locale = Locale(identifier: "en_US_POSIX")
    fallback.timeZone = TimeZone(identifier: "Asia/Seoul")
    for format in ["yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"] {
      fallback.dateFormat = format
      if let date = fallback.date(from: value) { return date }
    }
    return nil
  }
}
