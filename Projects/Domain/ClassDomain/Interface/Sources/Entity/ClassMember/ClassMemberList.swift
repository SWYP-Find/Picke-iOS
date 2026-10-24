public struct ClassMemberList: Equatable, Sendable {
  public let members: [ClassMember]
  public let currentMemberID: Int

  public init(
    members: [ClassMember],
    currentMemberID: Int
  ) {
    self.members = members
    self.currentMemberID = currentMemberID
  }
}
