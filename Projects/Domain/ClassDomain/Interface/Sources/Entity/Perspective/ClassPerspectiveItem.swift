import Foundation

public struct ClassPerspectiveItem: Equatable, Identifiable, Sendable {
  public let id: Int
  public let author: ClassPerspectiveAuthor
  public let option: ClassPerspectiveOption
  public let content: String
  public let likeCount: Int
  public let commentCount: Int
  public let isLiked: Bool
  public let isMyPerspective: Bool?
  public let status: String?
  public let createdAt: Date

  public init(
    id: Int,
    author: ClassPerspectiveAuthor,
    option: ClassPerspectiveOption,
    content: String,
    likeCount: Int,
    commentCount: Int,
    isLiked: Bool,
    isMyPerspective: Bool?,
    status: String?,
    createdAt: Date
  ) {
    self.id = id
    self.author = author
    self.option = option
    self.content = content
    self.likeCount = likeCount
    self.commentCount = commentCount
    self.isLiked = isLiked
    self.isMyPerspective = isMyPerspective
    self.status = status
    self.createdAt = createdAt
  }
}
