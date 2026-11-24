public struct ClassMemberList: Equatable, Sendable {
  public let members: [ClassMember]
  /// 비참여 운영자처럼 명단에 내 행이 없으면 nil.
  public let currentMemberID: Int?

  public init(
    members: [ClassMember],
    currentMemberID: Int?
  ) {
    self.members = members
    self.currentMemberID = currentMemberID
  }
}
