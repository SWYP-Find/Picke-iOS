public struct ClassPerspectiveOption: Equatable, Sendable {
  public let id: Int
  public let label: String
  public let title: String
  public let stance: String?

  public init(
    id: Int,
    label: String,
    title: String,
    stance: String?
  ) {
    self.id = id
    self.label = label
    self.title = title
    self.stance = stance
  }
}
