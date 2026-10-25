public struct ClassResultStats: Equatable, Sendable {
  public let activeMemberCount: Int
  public let completedCount: Int
  public let participationRate: Double
  public let commentWriterCount: Int
  public let commentRate: Double
  public let postVoteCount: Int
  public let options: [ClassResultOption]

  public init(
    activeMemberCount: Int,
    completedCount: Int,
    participationRate: Double,
    commentWriterCount: Int,
    commentRate: Double,
    postVoteCount: Int,
    options: [ClassResultOption]
  ) {
    self.activeMemberCount = activeMemberCount
    self.completedCount = completedCount
    self.participationRate = participationRate
    self.commentWriterCount = commentWriterCount
    self.commentRate = commentRate
    self.postVoteCount = postVoteCount
    self.options = options
  }
}
