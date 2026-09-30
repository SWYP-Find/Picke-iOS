import Foundation

public extension ClassRoom {
  static let mocks: [ClassRoom] = [
    ClassRoom(
      id: 1,
      name: "1학년 3반 사회 토론",
      joinCode: "PK7M2Q",
      battleId: 101,
      battleTitle: "촉법소년 연령을 낮춰야 할까?",
      deadline: Date(timeIntervalSince1970: 1_799_000_000),
      memberCount: 20,
      role: .owner,
      status: .open,
      isVoteEnabled: true,
      requiresComment: true
    ),
    ClassRoom(
      id: 2,
      name: "함께 생각하는 미술 수업",
      joinCode: "PK4B8R",
      battleId: 102,
      battleTitle: "뒤샹의 변기, 예술인가 도발인가",
      deadline: Date(timeIntervalSince1970: 1_799_000_000),
      memberCount: 18,
      role: .member,
      status: .open,
      isVoteEnabled: true,
      requiresComment: false
    ),
  ]

  static let mockJoinable = ClassRoom(
    id: 3,
    name: "철학 토론 수업",
    joinCode: "PK9T3S",
    battleId: 101,
    battleTitle: "촉법소년 연령을 낮춰야 할까?",
    deadline: Date(timeIntervalSince1970: 1_799_000_000),
    memberCount: 12,
    role: .member,
    status: .open,
    isVoteEnabled: true,
    requiresComment: true
  )
}

public extension ClassBattleSummary {
  static let mocks: [ClassBattleSummary] = [
    ClassBattleSummary(
      id: 101,
      title: "촉법소년 연령을 낮춰야 할까?",
      summary: "청소년 범죄와 보호의 균형을 이야기해요.",
      category: "사회",
      thumbnailURL: nil
    ),
    ClassBattleSummary(
      id: 102,
      title: "뒤샹의 변기, 예술인가 도발인가",
      summary: "예술의 경계를 함께 생각해요.",
      category: "예술",
      thumbnailURL: nil
    ),
  ]
}

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
      return matchesKeyword && matchesCategory
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
      battleId: battle.id,
      battleTitle: battle.title,
      deadline: creation.deadline,
      memberCount: 1,
      role: .owner,
      status: .open,
      isVoteEnabled: creation.isVoteEnabled,
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
      battleId: room.battleId,
      battleTitle: room.battleTitle,
      deadline: room.deadline,
      memberCount: room.memberCount + 1,
      role: .member,
      status: room.status,
      isVoteEnabled: room.isVoteEnabled,
      requiresComment: room.requiresComment
    )
    rooms.append(joined)
    availableRooms.remove(at: index)
    return joined
  }
}
