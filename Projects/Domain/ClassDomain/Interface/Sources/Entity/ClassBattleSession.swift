import Foundation

public struct ClassBattleSession: Equatable, Sendable {
  public let classID: Int
  public let myRole: ClassRole
  public let closeAt: Date
  public let closed: Bool
  public let commentRequired: Bool
  public let canParticipate: Bool
  public let participationCompleted: Bool
  public let battle: ClassBattleDetail

  public init(
    classID: Int,
    myRole: ClassRole,
    closeAt: Date,
    closed: Bool,
    commentRequired: Bool,
    canParticipate: Bool,
    participationCompleted: Bool,
    battle: ClassBattleDetail
  ) {
    self.classID = classID
    self.myRole = myRole
    self.closeAt = closeAt
    self.closed = closed
    self.commentRequired = commentRequired
    self.canParticipate = canParticipate
    self.participationCompleted = participationCompleted
    self.battle = battle
  }
}
