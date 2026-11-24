public struct ClassBattleTranscriptRow: Equatable, Identifiable, Sendable {
  public let id: Int
  public let line: ClassBattleTranscriptLine
  public let avatarFallback: String
  public let showsHeader: Bool
  public let isActive: Bool
  public let hasTopSpacing: Bool

  public init(
    line: ClassBattleTranscriptLine,
    avatarFallback: String,
    showsHeader: Bool,
    isActive: Bool,
    hasTopSpacing: Bool
  ) {
    self.id = line.id
    self.line = line
    self.avatarFallback = avatarFallback
    self.showsHeader = showsHeader
    self.isActive = isActive
    self.hasTopSpacing = hasTopSpacing
  }
}
