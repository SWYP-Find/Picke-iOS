import Foundation

public actor MockClassRepository: ClassInterface {
  private var rooms: [ClassRoom]
  private var availableRooms: [ClassRoom]
  private var membersByRoom: [Int: [ClassMember]]
  private var currentMemberIDs: [Int: Int]
  private var nextID: Int

  public init(
    rooms: [ClassRoom] = ClassRoom.mocks,
    availableRooms: [ClassRoom] = [ClassRoom.mockJoinable]
  ) {
    let previewNames = ["김선생", "공은지", "권동현", "김민지", "천다올", "유시영", "주천수", "김예은"]
    self.rooms = rooms
    self.availableRooms = availableRooms
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
    return updated
  }

  public func fetchMyClasses() async throws -> [ClassRoom] {
    rooms
  }

  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    ClassBattleSummary.mocks.filter { battle in
      let matchesKeyword = filter.keyword.isEmpty
        || battle.title.localizedCaseInsensitiveContains(filter.keyword)
        || battle.summary.localizedCaseInsensitiveContains(filter.keyword)
      let matchesCategory = filter.category.map { battle.category == $0 } ?? true
      return battle.level == filter.level && matchesCategory && matchesKeyword
    }
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    guard !creation.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          let battle = ClassBattleSummary.mocks.first(where: { $0.id == creation.battleId })
    else {
      throw ClassError.unknown("클래스 이름 또는 배틀이 올바르지 않습니다.")
    }

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
      requiresComment: creation.requiresComment
    )
    rooms.append(room)
    membersByRoom[id] = [ClassMember(id: 1, name: "운영자", isOwner: true)]
    currentMemberIDs[id] = 1
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
    let memberID = (members.map(\.id).max() ?? 0) + 1
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
      requiresComment: room.requiresComment
    )
    rooms.append(joined)
    availableRooms.remove(at: index)
    membersByRoom[room.id] = members
    currentMemberIDs[room.id] = memberID
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
      requiresComment: room.requiresComment
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
    membersByRoom[id] = nil
    currentMemberIDs[id] = nil
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
      requiresComment: requiresComment
    )
  }
}
