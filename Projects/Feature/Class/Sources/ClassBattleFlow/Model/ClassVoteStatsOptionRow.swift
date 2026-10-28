import ClassDomainInterface

public struct ClassVoteStatsOptionRow: Equatable, Identifiable, Sendable {
  public let id: Int
  public let option: ClassVoteStatsOption
  public let avatarFallback: String
  public let percentageLabel: String

  public init(
    index: Int,
    option: ClassVoteStatsOption,
    avatarFallback: String,
    percentageLabel: String
  ) {
    self.id = index
    self.option = option
    self.avatarFallback = avatarFallback
    self.percentageLabel = percentageLabel
  }
}
