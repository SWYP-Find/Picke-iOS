public struct ClassResultStats: Equatable, Sendable {
  public let activeMemberCount: Int
  public let completedCount: Int
  public let participationRate: Double
  public let commentWriterCount: Int
  public let commentRate: Double
  public let postVoteCount: Int
  public let midVoteEnabled: Bool
  public let midVoteCount: Int
  public let midVoteCheckpoints: [ClassResultMidVoteCheckpoint]
  public let options: [ClassResultOption]

  public init(
    activeMemberCount: Int,
    completedCount: Int,
    participationRate: Double,
    commentWriterCount: Int,
    commentRate: Double,
    postVoteCount: Int,
    midVoteEnabled: Bool = false,
    midVoteCount: Int = 0,
    midVoteCheckpoints: [ClassResultMidVoteCheckpoint] = [],
    options: [ClassResultOption]
  ) {
    self.activeMemberCount = activeMemberCount
    self.completedCount = completedCount
    self.participationRate = participationRate
    self.commentWriterCount = commentWriterCount
    self.commentRate = commentRate
    self.postVoteCount = postVoteCount
    self.midVoteEnabled = midVoteEnabled
    self.midVoteCount = midVoteCount
    self.midVoteCheckpoints = midVoteCheckpoints
    self.options = options
  }
}
