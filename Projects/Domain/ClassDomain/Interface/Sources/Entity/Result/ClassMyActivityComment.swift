import Foundation

/// 내가 다른 의견에 남긴 댓글 한 건.
public struct ClassMyActivityComment: Equatable, Sendable, Identifiable {
  public let id: Int
  public let perspectiveID: Int
  public let perspectiveTitle: String
  public let stance: String
  public let content: String
  public let likeCount: Int
  public let createdAt: Date?

  public init(
    id: Int,
    perspectiveID: Int,
    perspectiveTitle: String,
    stance: String,
    content: String,
    likeCount: Int,
    createdAt: Date?
  ) {
    self.id = id
    self.perspectiveID = perspectiveID
    self.perspectiveTitle = perspectiveTitle
    self.stance = stance
    self.content = content
    self.likeCount = likeCount
    self.createdAt = createdAt
  }
}
