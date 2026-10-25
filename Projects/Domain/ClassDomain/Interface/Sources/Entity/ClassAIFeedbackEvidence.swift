public struct ClassAIFeedbackEvidence: Equatable, Sendable {
  public let sourceType: String?
  public let sourceID: Int?
  public let content: String
  public let quote: String?
  public let field: String?

  public init(
    sourceType: String? = nil,
    sourceID: Int? = nil,
    content: String,
    quote: String? = nil,
    field: String? = nil
  ) {
    self.sourceType = sourceType
    self.sourceID = sourceID
    self.content = content
    self.quote = quote
    self.field = field
  }
}
