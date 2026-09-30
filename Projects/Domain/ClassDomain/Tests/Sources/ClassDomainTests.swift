import ClassDomainInterface
import Foundation
import Testing

struct ClassDomainTests {
  @Test
  func 생성한_클래스는_목록에_추가되고_선생님_역할을_갖는다() async throws {
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    let created = try await repository.createClass(
      ClassCreation(
        name: "토론 수업",
        deadline: Date(timeIntervalSince1970: 1_800_000_000),
        battleId: 101,
        isVoteEnabled: true,
        requiresComment: false
      )
    )

    #expect(created.role == .owner)
    #expect(created.battleId == 101)
    #expect(try await repository.fetchMyClasses() == [created])
    #expect(try await repository.fetchClass(joinCode: created.joinCode) == created)
  }

  @Test
  func 참여하면_학생_역할로_목록에_추가되고_중복_참여는_거부한다() async throws {
    let repository = MockClassRepository(rooms: [], availableRooms: [.mockJoinable])
    let joined = try await repository.joinClass(joinCode: "PK9T3S", nickname: "민지")

    #expect(joined.role == .member)
    #expect(joined.memberCount == ClassRoom.mockJoinable.memberCount + 1)
    #expect(try await repository.fetchMyClasses() == [joined])
    do {
      _ = try await repository.joinClass(joinCode: "PK9T3S", nickname: "민지")
      Issue.record("중복 참여가 허용됨")
    } catch {
      #expect(ClassError.from(error) == .alreadyJoined)
    }
  }

  @Test
  func 없는_참여_코드는_거부한다() async throws {
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    do {
      _ = try await repository.fetchClass(joinCode: "INVALID")
      Issue.record("없는 참여 코드가 허용됨")
    } catch {
      #expect(ClassError.from(error) == .invalidCode)
    }
  }
}
