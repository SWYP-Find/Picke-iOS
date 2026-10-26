public struct ClassResultOption: Equatable, Identifiable, Sendable {
  public let id: Int
  public let title: String
  public let preVoteCount: Int
  public let postVoteCount: Int
  public let postVoteRatio: Double

  public init(
    id: Int,
    title: String,
    preVoteCount: Int,
    postVoteCount: Int,
    postVoteRatio: Double
  ) {
    self.id = id
    self.title = title
    self.preVoteCount = preVoteCount
    self.postVoteCount = postVoteCount
    self.postVoteRatio = postVoteRatio
  }
}
