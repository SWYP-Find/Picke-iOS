public struct ClassVoteChoice: Equatable, Sendable {
  public let optionID: Int
  public let label: String
  public let title: String

  public init(optionID: Int, label: String, title: String) {
    self.optionID = optionID
    self.label = label
    self.title = title
  }
}
