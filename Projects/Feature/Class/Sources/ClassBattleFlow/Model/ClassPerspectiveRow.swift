import ClassDomainInterface
import PickeCoreUtility

public struct ClassPerspectiveRow: Equatable, Identifiable {
  public let id: Int
  public let perspective: ClassPerspectiveItem
  public let likeCountLabel: String
  public let commentCountLabel: String
  public let menuKind: ClassPerspectiveMenuKind

  public var createdAtLabel: String { perspective.createdAt.relativeKoreanString }

  /// 공개되지 않은 내 의견의 상태 배지 문구(Android `comment_status_pending/rejected`).
  public var statusBadgeTitle: String? {
    if isPendingReview { return "검수중" }
    if isRejected { return "거절됨" }
    return nil
  }

  public var isPendingReview: Bool { perspective.status?.uppercased() == "PENDING" }
  public var isRejected: Bool { perspective.status?.uppercased() == "REJECTED" }

  public init(
    id: Int,
    perspective: ClassPerspectiveItem,
    likeCountLabel: String,
    commentCountLabel: String,
    menuKind: ClassPerspectiveMenuKind? = nil
  ) {
    self.id = id
    self.perspective = perspective
    self.likeCountLabel = likeCountLabel
    self.commentCountLabel = commentCountLabel
    self.menuKind = menuKind ?? ClassPerspectiveMenuKind(listItem: perspective)
  }
}
