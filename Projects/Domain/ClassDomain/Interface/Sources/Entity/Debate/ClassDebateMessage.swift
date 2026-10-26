public struct ClassDebateMessage: Equatable, Identifiable, Sendable {
  public let id: Int
  public let round: Int
  public let speaker: ClassDebateSpeaker
  public let content: String

  public init(
    id: Int,
    round: Int,
    speaker: ClassDebateSpeaker,
    content: String
  ) {
    self.id = id
    self.round = round
    self.speaker = speaker
    self.content = content
  }
}
