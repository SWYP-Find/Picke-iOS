import Foundation

/// 클래스 결과의 내 활동. 받은 추천 수와 내가 남긴 댓글을 커서 단위로 받는다.
public struct ClassMyActivity: Equatable, Sendable {
  public let classID: Int
  public let receivedLikeCount: Int
  public let commentCount: Int
  public let comments: [ClassMyActivityComment]
  public let nextCursor: String?
  public let hasNext: Bool

  public init(
    classID: Int,
    receivedLikeCount: Int,
    commentCount: Int,
    comments: [ClassMyActivityComment],
    nextCursor: String?,
    hasNext: Bool
  ) {
    self.classID = classID
    self.receivedLikeCount = receivedLikeCount
    self.commentCount = commentCount
    self.comments = comments
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }
}
