import ClassDomainInterface

public struct ClassBattleProgress: Equatable, Sendable {
  public let session: ClassBattleSession
  public let voteHistory: ClassVoteHistory?

  public init(
    session: ClassBattleSession,
    voteHistory: ClassVoteHistory?
  ) {
    self.session = session
    self.voteHistory = voteHistory
  }
}
