public struct ClassTopicFilter: Equatable, Sendable {
  public var keyword: String
  public var level: ClassAudienceLevel
  public var category: ClassCategory?

  public init(
    keyword: String = "",
    level: ClassAudienceLevel = .middle,
    category: ClassCategory? = nil
  ) {
    self.keyword = keyword
    self.level = level
    self.category = category
  }
}
