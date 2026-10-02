public struct ClassOwnerMember: Equatable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let participationCount: Int
  public let needsReview: Bool

  public init(
    id: Int,
    name: String,
    participationCount: Int,
    needsReview: Bool = false
  ) {
    self.id = id
    self.name = name
    self.participationCount = participationCount
    self.needsReview = needsReview
  }
}
