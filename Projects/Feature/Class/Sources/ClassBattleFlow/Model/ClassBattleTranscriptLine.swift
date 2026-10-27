public struct ClassBattleTranscriptLine: Equatable, Identifiable, Sendable {
  public let id: Int
  public let startTime: Double
  public let speakerName: String
  public let speakerImageURL: String?
  public let text: String
  public let side: String

  public init(
    id: Int,
    startTime: Double,
    speakerName: String,
    speakerImageURL: String?,
    text: String,
    side: String
  ) {
    self.id = id
    self.startTime = startTime
    self.speakerName = speakerName
    self.speakerImageURL = speakerImageURL
    self.text = text
    self.side = side
  }
}
