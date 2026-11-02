import ClassDomainInterface
import PickeCoreUtility

public struct ClassPerspectiveRow: Equatable, Identifiable {
  public let id: Int
  public let perspective: ClassPerspectiveItem
  public let likeCountLabel: String
  public let commentCountLabel: String

  public var createdAtLabel: String { perspective.createdAt.relativeKoreanString }

  public init(
    id: Int,
    perspective: ClassPerspectiveItem,
    likeCountLabel: String,
    commentCountLabel: String
  ) {
    self.id = id
    self.perspective = perspective
    self.likeCountLabel = likeCountLabel
    self.commentCountLabel = commentCountLabel
  }
}
