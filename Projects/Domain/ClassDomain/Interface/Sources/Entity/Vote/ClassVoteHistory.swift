public struct ClassVoteHistory: Equatable, Sendable {
  public let battleTitle: String
  public let preVote: ClassVoteChoice
  public let midVotes: [ClassMidVoteChoice]
  public let postVote: ClassVoteChoice?
  public let status: ClassBattleStep
  public let opinionChanged: Bool?

  public init(
    battleTitle: String,
    preVote: ClassVoteChoice,
    midVotes: [ClassMidVoteChoice] = [],
    postVote: ClassVoteChoice?,
    status: ClassBattleStep,
    opinionChanged: Bool?
  ) {
    self.battleTitle = battleTitle
    self.preVote = preVote
    self.midVotes = midVotes
    self.postVote = postVote
    self.status = status
    self.opinionChanged = opinionChanged
  }
}
