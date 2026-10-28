public struct ClassResultMidVoteCheckpoint: Equatable, Identifiable, Sendable {
  public let id: Int
  public let voteCount: Int
  public let options: [ClassResultMidVoteOption]

  public init(
    id: Int,
    voteCount: Int,
    options: [ClassResultMidVoteOption]
  ) {
    self.id = id
    self.voteCount = voteCount
    self.options = options
  }
}
