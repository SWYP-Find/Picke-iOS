//
//  MockClassRepository.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public actor MockClassRepository: ClassInterface {
  private var rooms: [ClassRoom]
  private var availableRooms: [ClassRoom]
  private var membersByRoom: [Int: [ClassMember]]
  private var currentMemberIDs: [Int: Int]
  private var nextMemberIDs: [Int: Int]
  private var reports: [Int: ClassReport]
  private var dashboards: [Int: ClassOwnerDashboardData]
  private var nextID: Int

  public init(
    rooms: [ClassRoom] = ClassRoom.mocks + [.mockClosedSociety],
    availableRooms: [ClassRoom] = [ClassRoom.mockJoinable],
    reports: [Int: ClassReport]? = nil,
    dashboards: [Int: ClassOwnerDashboardData]? = nil
  ) {
    let previewNames = ["김선생", "공은지", "권동현", "김민지", "천다올", "유시영", "주천수", "김예은"]
    let initialRooms = rooms + availableRooms
    let initialIDs = Set(initialRooms.map(\.id))
    self.rooms = rooms
    self.availableRooms = availableRooms
    self.reports = (reports ?? Dictionary(uniqueKeysWithValues: rooms.compactMap { room in
      room == .mockJoinable || room == .mockClosedSociety
        ? (room.id, MockClassReport.figma) : nil
    })).filter { initialIDs.contains($0.key) }
    self.dashboards = (dashboards ?? Dictionary(uniqueKeysWithValues: initialRooms.compactMap { room in
      room == ClassRoom.mocks[0] ? (room.id, MockClassOwnerDashboard.figma) : nil
    })).filter { initialIDs.contains($0.key) }
    membersByRoom = Dictionary(
      uniqueKeysWithValues: (rooms + availableRooms).map { room in
        (room.id, (1 ... max(1, room.memberCount)).map { id in
          let name = room.id == ClassRoom.mocks[0].id && id <= previewNames.count
            ? previewNames[id - 1]
            : (id == 1 ? "운영자" : "참여자 \(id)")
          return ClassMember(id: id, name: name, isOwner: id == 1)
        })
      }
    )
    currentMemberIDs = Dictionary(uniqueKeysWithValues: rooms.map { ($0.id, $0.role == .owner ? 1 : 2) })
    nextMemberIDs = Dictionary(uniqueKeysWithValues: initialRooms.map { ($0.id, max(1, $0.memberCount) + 1) })
    nextID = (rooms + availableRooms).map(\.id).max().map { $0 + 1 } ?? 1
  }

  public func fetchMembers(roomID: Int) async throws -> [ClassMember] {
    guard let members = membersByRoom[roomID] else { throw ClassError.invalidCode }
    return members
  }

  public func currentMemberID(roomID: Int) async throws -> Int {
    guard let id = currentMemberIDs[roomID] else { throw ClassError.invalidCode }
    return id
  }

  public func removeMember(roomID: Int, memberID: Int, currentMemberID: Int) async throws -> ClassRoom {
    guard let roomIndex = rooms.firstIndex(where: { $0.id == roomID }),
          var members = membersByRoom[roomID]
    else { throw ClassError.invalidCode }
    guard rooms[roomIndex].role == .owner, currentMemberID == 1,
          currentMemberIDs[roomID] == currentMemberID,
          memberID != 1, memberID != currentMemberID,
          let memberIndex = members.firstIndex(where: { $0.id == memberID && !$0.isOwner })
    else { throw ClassError.unknown("운영자만 다른 참여자를 내보낼 수 있습니다.") }

    members.remove(at: memberIndex)
    membersByRoom[roomID] = members
    if let dashboard = dashboards[roomID] {
      replaceDashboardMembers(roomID: roomID, with: dashboard.members.filter { $0.id != memberID })
    }
    rooms[roomIndex] = rooms[roomIndex].withMemberCount(members.count)
    return rooms[roomIndex]
  }

  public func updateDisplayName(
    roomID: Int,
    memberID: Int,
    currentMemberID: Int,
    name: String
  ) async throws -> ClassMember {
    guard var members = membersByRoom[roomID],
          let index = members.firstIndex(where: { $0.id == memberID })
    else { throw ClassError.invalidCode }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard memberID == currentMemberID,
          currentMemberIDs[roomID] == currentMemberID,
          !trimmed.isEmpty
    else {
      throw ClassError.unknown("본인 이름만 수정할 수 있습니다.")
    }
    let updated = ClassMember(id: memberID, name: trimmed, isOwner: members[index].isOwner)
    members[index] = updated
    membersByRoom[roomID] = members
    if let dashboard = dashboards[roomID] {
      replaceDashboardMembers(roomID: roomID, with: dashboard.members.map { member in
        guard member.id == memberID else { return member }
        return ClassOwnerMember(
          id: member.id,
          name: trimmed,
          participationCount: member.participationCount,
          needsReview: member.needsReview
        )
      })
    }
    return updated
  }

  private func replaceDashboardMembers(roomID: Int, with members: [ClassOwnerMember]) {
    guard let dashboard = dashboards[roomID] else { return }
    dashboards[roomID] = ClassOwnerDashboardData(
      members: members,
      opinions: dashboard.opinions,
      report: dashboard.report,
      metrics: dashboard.metrics,
      insight: dashboard.insight
    )
  }

  public func fetchMyClasses() async throws -> [ClassRoom] {
    rooms
  }

  public func fetchReport(roomID: Int) async throws -> ClassReport? {
    guard rooms.contains(where: { $0.id == roomID }) else { throw ClassError.invalidCode }
    return reports[roomID]
  }

  public func fetchOwnerDashboard(roomID: Int) async throws -> ClassOwnerDashboardData? {
    guard let room = rooms.first(where: { $0.id == roomID }) else { throw ClassError.invalidCode }
    guard room.role == .owner else {
      throw ClassError.unknown("클래스 관리자만 대시보드를 볼 수 있습니다.")
    }
    return dashboards[roomID]
  }

  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    ClassBattleSummary.mocks.filter { battle in
      let matchesKeyword = filter.keyword.isEmpty
        || battle.title.localizedCaseInsensitiveContains(filter.keyword)
        || battle.summary.localizedCaseInsensitiveContains(filter.keyword)
      let matchesCategory = filter.categories.isEmpty || filter.categories.contains(battle.category)
      return battle.level == filter.level && matchesCategory && matchesKeyword
    }
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    guard !creation.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          let battle = ClassBattleSummary.mocks.first(where: { $0.id == creation.battleId })
    else {
      throw ClassError.unknown("클래스 이름 또는 배틀이 올바르지 않습니다.")
    }

    return makeClass(creation, battle: battle)
  }

  /// AI 질문 미리보기 전용. 라이브 ClassInterface의 생성 계약에는 포함하지 않는다.
  public func createClass(_ creation: ClassCreation, battle: ClassBattleSummary) async throws -> ClassRoom {
    guard !creation.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          creation.battleId == battle.id,
          battle.id < 0
    else {
      throw ClassError.unknown("클래스 이름 또는 배틀이 올바르지 않습니다.")
    }

    return makeClass(creation, battle: battle)
  }

  private func makeClass(_ creation: ClassCreation, battle: ClassBattleSummary) -> ClassRoom {
    let id = nextID
    nextID += 1
    let room = ClassRoom(
      id: id,
      name: creation.name,
      joinCode: String(format: "PK%04d", id),
      battle: battle,
      deadline: creation.deadline,
      memberCount: 1,
      role: .owner,
      status: .open,
      allowsAnonymousOpinion: creation.allowsAnonymousOpinion,
      requiresComment: creation.requiresComment,
      ownerParticipates: creation.ownerParticipates
    )
    rooms.append(room)
    reports[id] = nil
    dashboards[id] = nil
    membersByRoom[id] = [ClassMember(id: 1, name: "운영자", isOwner: true)]
    currentMemberIDs[id] = 1
    nextMemberIDs[id] = 2
    return room
  }

  public func fetchClass(joinCode: String) async throws -> ClassRoom {
    guard let room = (rooms + availableRooms).first(where: { $0.joinCode == joinCode }) else {
      throw ClassError.invalidCode
    }
    return room
  }

  public func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ClassError.unknown("이름을 입력해주세요.")
    }
    guard !rooms.contains(where: { $0.joinCode == joinCode }) else {
      throw ClassError.alreadyJoined
    }
    guard let index = availableRooms.firstIndex(where: { $0.joinCode == joinCode }) else {
      throw ClassError.invalidCode
    }

    let room = availableRooms[index]
    guard room.status == .open else { throw ClassError.closed }
    var members = membersByRoom[room.id] ?? []
    let memberID = nextMemberIDs[room.id] ?? ((members.map(\.id).max() ?? 0) + 1)
    members.append(ClassMember(id: memberID, name: nickname.trimmingCharacters(in: .whitespacesAndNewlines)))
    let joined = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: room.deadline,
      memberCount: members.count,
      role: .member,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment,
      ownerParticipates: room.ownerParticipates
    )
    rooms.append(joined)
    availableRooms.remove(at: index)
    membersByRoom[room.id] = members
    currentMemberIDs[room.id] = memberID
    nextMemberIDs[room.id] = memberID + 1
    return joined
  }

  public func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    guard let index = rooms.firstIndex(where: { $0.id == id }) else {
      throw ClassError.invalidCode
    }
    let room = rooms[index]
    guard room.role == .owner else {
      throw ClassError.unknown("클래스 관리자만 마감일을 변경할 수 있습니다.")
    }
    let updated = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: deadline,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment,
      ownerParticipates: room.ownerParticipates
    )
    rooms[index] = updated
    return updated
  }

  public func deleteClass(id: Int) async throws {
    guard let index = rooms.firstIndex(where: { $0.id == id }) else {
      throw ClassError.invalidCode
    }
    guard rooms[index].role == .owner else {
      throw ClassError.unknown("클래스 관리자만 삭제할 수 있습니다.")
    }
    rooms.remove(at: index)
    reports[id] = nil
    dashboards[id] = nil
    membersByRoom[id] = nil
    currentMemberIDs[id] = nil
    nextMemberIDs[id] = nil
  }

  public func leaveClass(id: Int) async throws {
    guard let roomIndex = rooms.firstIndex(where: { $0.id == id }) else {
      throw ClassError.invalidCode
    }
    let room = rooms[roomIndex]
    guard room.role == .member else {
      throw ClassError.unknown("클래스 참여자만 나갈 수 있습니다.")
    }
    guard let memberID = currentMemberIDs[id],
          var members = membersByRoom[id],
          let memberIndex = members.firstIndex(where: { $0.id == memberID && !$0.isOwner })
    else {
      throw ClassError.invalidCode
    }

    members.remove(at: memberIndex)
    rooms.remove(at: roomIndex)
    membersByRoom[id] = members
    currentMemberIDs[id] = nil
    // This room-keyed report is the current mock user's personal snapshot.
    reports[id] = nil
    availableRooms.removeAll { $0.id == id }
    availableRooms.append(room.withMemberCount(members.count))
  }
}

private extension ClassRoom {
  func withMemberCount(_ memberCount: Int) -> ClassRoom {
    ClassRoom(
      id: id,
      name: name,
      joinCode: joinCode,
      battle: battle,
      deadline: deadline,
      memberCount: memberCount,
      role: role,
      status: status,
      allowsAnonymousOpinion: allowsAnonymousOpinion,
      requiresComment: requiresComment,
      ownerParticipates: ownerParticipates
    )
  }
}
