public struct ClassResultMidVoteOption: Equatable, Identifiable, Sendable {
  public let id: Int
  public let label: String
  public let voteCount: Int
  public let ratio: Double

  public init(
    id: Int,
    label: String,
    voteCount: Int,
    ratio: Double
  ) {
    self.id = id
    self.label = label
    self.voteCount = voteCount
    self.ratio = ratio
  }
}
