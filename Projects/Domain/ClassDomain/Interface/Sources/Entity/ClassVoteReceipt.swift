public struct ClassVoteReceipt: Equatable, Sendable {
  public let voteID: Int
  public let status: ClassBattleStep

  public init(voteID: Int, status: ClassBattleStep) {
    self.voteID = voteID
    self.status = status
  }
}
