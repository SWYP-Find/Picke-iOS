import ClassDomainInterface
import Foundation
import PickeCoreUtility

extension ClassMyActivityDTO.Comment {
  /// Android와 같이 댓글·의견 ID가 없는 항목은 버린다.
  func toDomain() -> ClassMyActivityComment? {
    guard let commentId, let perspectiveId else { return nil }
    return ClassMyActivityComment(
      id: commentId,
      perspectiveID: perspectiveId,
      perspectiveTitle: perspectiveTitle ?? "",
      stance: stance ?? "",
      content: content ?? "",
      likeCount: likeCount ?? 0,
      createdAt: createdAt.flatMap(ServerDateParser.parse)
    )
  }
}

extension ClassMyActivityDTO {
  func toDomain(fallbackClassID: Int) -> ClassMyActivity {
    ClassMyActivity(
      classID: classId ?? fallbackClassID,
      receivedLikeCount: receivedLikeCount ?? 0,
      commentCount: commentCount ?? 0,
      comments: comments?.compactMap { $0.toDomain() } ?? [],
      nextCursor: nextCursor,
      hasNext: hasNext ?? false
    )
  }
}
