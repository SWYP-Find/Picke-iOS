public struct ClassOwnerOpinion: Equatable, Identifiable, Sendable {
  public let id: Int
  public let author: String
  public let text: String
  public let replyCount: Int
  public let isReported: Bool

  public init(
    id: Int,
    author: String,
    text: String,
    replyCount: Int,
    isReported: Bool = false
  ) {
    self.id = id
    self.author = author
    self.text = text
    self.replyCount = replyCount
    self.isReported = isReported
  }
}
