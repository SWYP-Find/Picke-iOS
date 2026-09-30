import Foundation

public actor MockClassRepository: ClassInterface {
  private var rooms: [ClassRoom]
  private var availableRooms: [ClassRoom]
  private var nextID: Int

  public init(
    rooms: [ClassRoom] = ClassRoom.mocks,
    availableRooms: [ClassRoom] = [ClassRoom.mockJoinable]
  ) {
    self.rooms = rooms
    self.availableRooms = availableRooms
    nextID = (rooms + availableRooms).map(\.id).max().map { $0 + 1 } ?? 1
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
    let joined = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: room.deadline,
      memberCount: room.memberCount + 1,
      role: .member,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment
    )
    rooms.append(joined)
    availableRooms.remove(at: index)
    return joined
  }
}
