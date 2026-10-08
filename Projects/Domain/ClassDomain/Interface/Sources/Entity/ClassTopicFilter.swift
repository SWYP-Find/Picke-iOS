public struct ClassTopicFilter: Equatable, Sendable {
  public var keyword: String
  public var level: ClassAudienceLevel
  public var categories: [ClassCategory]

  public var category: ClassCategory? {
    categories.first
  }

  public init(
    keyword: String = "",
    level: ClassAudienceLevel = .middle,
    categories: [ClassCategory] = []
  ) {
    self.keyword = keyword
    self.level = level
    self.categories = categories
  }

  public init(
    keyword: String = "",
    level: ClassAudienceLevel = .middle,
    category: ClassCategory
  ) {
    self.init(keyword: keyword, level: level, categories: [category])
  }
}
