import Foundation

public struct ClassRoom: Equatable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let joinCode: String
  public let battle: ClassBattleSummary
  public let deadline: Date
  public let memberCount: Int
  public let role: ClassRole
  public let status: ClassStatus
  public let allowsAnonymousOpinion: Bool
  public let requiresComment: Bool

  public init(
    id: Int,
    name: String,
    joinCode: String,
    battle: ClassBattleSummary,
    deadline: Date,
    memberCount: Int,
    role: ClassRole,
    status: ClassStatus,
    allowsAnonymousOpinion: Bool,
    requiresComment: Bool
  ) {
    self.id = id
    self.name = name
    self.joinCode = joinCode
    self.battle = battle
    self.deadline = deadline
    self.memberCount = memberCount
    self.role = role
    self.status = status
    self.allowsAnonymousOpinion = allowsAnonymousOpinion
    self.requiresComment = requiresComment
  }
}

public extension ClassRoom {
  static let mocks: [ClassRoom] = [
    .init(
      id: 1,
      name: "1학년 3반 사회 토론",
      joinCode: "PK7M2Q",
      battle: ClassBattleSummary.mocks[0],
      deadline: Date(timeIntervalSince1970: 1_799_000_000),
      memberCount: 20,
      role: .owner,
      status: .open,
      allowsAnonymousOpinion: true,
      requiresComment: true
    ),
    .init(
      id: 2,
      name: "함께 생각하는 미술 수업",
      joinCode: "PK4B8R",
      battle: ClassBattleSummary.mocks[1],
      deadline: Date(timeIntervalSince1970: 1_799_000_000),
      memberCount: 18,
      role: .member,
      status: .open,
      allowsAnonymousOpinion: true,
      requiresComment: false
    ),
  ]

  static let mockJoinable = ClassRoom(
    id: 3,
    name: "사회 토론 수업",
    joinCode: "PK9T3S",
    battle: ClassBattleSummary.mocks[0],
    deadline: Date(timeIntervalSince1970: 1_799_000_000),
    memberCount: 12,
    role: .member,
    status: .open,
    allowsAnonymousOpinion: true,
    requiresComment: true
  )
}
