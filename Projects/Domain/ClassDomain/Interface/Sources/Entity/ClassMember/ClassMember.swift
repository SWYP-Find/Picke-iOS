public struct ClassMember: Equatable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let isOwner: Bool

  public init(id: Int, name: String, isOwner: Bool = false) {
    self.id = id
    self.name = name
    self.isOwner = isOwner
  }
}
