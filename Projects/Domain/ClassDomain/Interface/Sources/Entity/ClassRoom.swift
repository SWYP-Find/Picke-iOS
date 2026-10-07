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
      deadline: Date(timeIntervalSince1970: 1_790_154_000),
      memberCount: 32,
      role: .owner,
      status: .open,
      allowsAnonymousOpinion: true,
      requiresComment: true
    ),
    .init(
      id: 2,
      name: "윤리와 사상 토론 클래스",
      joinCode: "PK4B8R",
      battle: ClassBattleSummary.mocks[3],
      deadline: Date(timeIntervalSince1970: 1_790_154_000),
      memberCount: 32,
      role: .member,
      status: .open,
      allowsAnonymousOpinion: true,
      requiresComment: false
    ),
    .init(
      id: 3,
      name: "주간 독서토론 모임",
      joinCode: "PK5L9D",
      battle: ClassBattleSummary.mocks[4],
      deadline: Date(timeIntervalSince1970: 1_790_154_000),
      memberCount: 32,
      role: .owner,
      status: .closed,
      allowsAnonymousOpinion: true,
      requiresComment: true
    ),
  ]

  static let mockJoinable = ClassRoom(
    id: 4,
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
