public struct ClassReportHighlightRow: Equatable, Identifiable {
  public let id: Int
  public let title: String
  public let text: String
  public let isLast: Bool

  public var quotedText: String { "“\(text)”" }

  public init(
    id: Int,
    title: String,
    text: String,
    isLast: Bool
  ) {
    self.id = id
    self.title = title
    self.text = text
    self.isLast = isLast
  }
}
