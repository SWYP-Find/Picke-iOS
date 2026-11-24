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
  /// 사용 좌석 수. 활동한 뒤 나간 사람도 포함한다. 남은 자리는 `memberCapacity - memberCount`.
  public let memberCount: Int
  /// 현재 명단 인원(참여하는 운영자 포함). 화면의 "멤버 N명"에 쓴다.
  public let activeMemberCount: Int
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
    activeMemberCount: Int? = nil,
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
    self.activeMemberCount = activeMemberCount ?? memberCount
    self.memberCapacity = memberCapacity
    self.role = role
    self.status = status
    self.allowsAnonymousOpinion = allowsAnonymousOpinion
    self.requiresComment = requiresComment
    self.ownerParticipates = ownerParticipates
  }
}

public extension ClassRoom {
  /// Android ClassDetail·ClassShare 처럼 `/classes/{id}/battle` 응답으로 배틀 카드의
  /// 카테고리 태그·입장·소요 시간을 채운다. 상세 응답의 배틀은 제목·요약만 준다.
  func applyingBattle(_ detail: ClassBattleDetail) -> ClassRoom {
    let optionA = detail.options.first
    let optionB = detail.options.dropFirst().first
    // `/battle` 은 입장 설명을 주지 않으므로 같은 배틀이면 기존 설명을 유지한다.
    let isSameBattle = battle.id == detail.id
    let summary = ClassBattleSummary(
      id: detail.id,
      title: detail.title,
      summary: detail.summary,
      thumbnailURL: detail.thumbnailURL ?? battle.thumbnailURL,
      philosopherA: optionA?.representative ?? "",
      optionATitle: optionA?.title ?? "",
      optionADescription: isSameBattle ? battle.optionADescription : nil,
      philosopherAImageURL: optionA?.imageURL,
      philosopherB: optionB?.representative ?? "",
      optionBTitle: optionB?.title ?? "",
      optionBDescription: isSameBattle ? battle.optionBDescription : nil,
      philosopherBImageURL: optionB?.imageURL,
      category: battle.category,
      categoryDisplayTitle: detail.categoryTags.first ?? "",
      level: battle.level,
      audioDuration: detail.audioDuration,
      viewCount: battle.viewCount,
      commentCount: battle.commentCount
    )
    return ClassRoom(
      id: id,
      name: name,
      joinCode: joinCode,
      battle: summary,
      deadline: deadline,
      closeAt: closeAt,
      memberCount: memberCount,
      activeMemberCount: activeMemberCount,
      role: role,
      status: status,
      allowsAnonymousOpinion: allowsAnonymousOpinion,
      requiresComment: requiresComment,
      ownerParticipates: ownerParticipates,
      memberCapacity: memberCapacity,
      battleType: battleType,
      ticketExpiresAt: ticketExpiresAt
    )
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
