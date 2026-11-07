public struct ClassMidVoteChoice: Equatable, Sendable {
  public let checkpointID: Int
  public let optionID: Int
  public let label: String

  public init(
    checkpointID: Int,
    optionID: Int,
    label: String
  ) {
    self.checkpointID = checkpointID
    self.optionID = optionID
    self.label = label
  }
}
