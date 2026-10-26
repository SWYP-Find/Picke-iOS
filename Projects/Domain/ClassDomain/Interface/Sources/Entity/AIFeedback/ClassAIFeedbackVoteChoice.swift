public struct ClassAIFeedbackVoteChoice: Equatable, Sendable {
  public let id: Int
  public let title: String
  public let stance: String?

  public init(
    id: Int,
    title: String,
    stance: String? = nil
  ) {
    self.id = id
    self.title = title
    self.stance = stance
  }
}
