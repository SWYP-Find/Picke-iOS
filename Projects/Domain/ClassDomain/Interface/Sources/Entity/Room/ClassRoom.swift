//
//  ClassRoom.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct ClassRoom: Equatable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let joinCode: String
  public let battle: ClassBattleSummary
  public let battleType: ClassBattleType
  public let deadline: Date
  public let ticketExpiresAt: Date?
  public let closeAt: Date?
  public let memberCount: Int
  public let memberCapacity: Int?
  public let role: ClassRole
  public let status: ClassStatus
  public let allowsAnonymousOpinion: Bool
  public let requiresComment: Bool
  public let ownerParticipates: Bool

  public init(
    id: Int,
    name: String,
    joinCode: String,
    battle: ClassBattleSummary,
    deadline: Date,
    closeAt: Date? = nil,
    memberCount: Int,
    role: ClassRole,
    status: ClassStatus,
    allowsAnonymousOpinion: Bool,
    requiresComment: Bool,
    ownerParticipates: Bool = true,
    memberCapacity: Int? = nil,
    battleType: ClassBattleType = .tts,
    ticketExpiresAt: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.joinCode = joinCode
    self.battle = battle
    self.battleType = battleType
    self.deadline = deadline
    self.ticketExpiresAt = ticketExpiresAt
    self.closeAt = closeAt
    self.memberCount = memberCount
    self.memberCapacity = memberCapacity
    self.role = role
    self.status = status
    self.allowsAnonymousOpinion = allowsAnonymousOpinion
    self.requiresComment = requiresComment
    self.ownerParticipates = ownerParticipates
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
      role: .owner,
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

  static let mockClosedSociety = ClassRoom(
    id: 5,
    name: "1학년 3반 사회 토론",
    joinCode: "PK3R5T",
    battle: ClassBattleSummary.mocks[0],
    deadline: Date(timeIntervalSince1970: 1_790_154_000),
    memberCount: 32,
    role: .member,
    status: .closed,
    allowsAnonymousOpinion: true,
    requiresComment: true
  )

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
