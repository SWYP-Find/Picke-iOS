public struct ClassPerspectivePage: Equatable, Sendable {
  public let items: [ClassPerspectiveItem]
  public let nextCursor: String?
  public let hasNext: Bool

  public init(
    items: [ClassPerspectiveItem],
    nextCursor: String?,
    hasNext: Bool
  ) {
    self.items = items
    self.nextCursor = nextCursor
    self.hasNext = hasNext
  }
}
