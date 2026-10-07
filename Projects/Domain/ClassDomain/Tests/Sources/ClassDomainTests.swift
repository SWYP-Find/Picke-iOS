import ClassDomain
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

struct ClassDomainTests {
  @Test
  func live_저장소는_mock_클래스를_반환하지_않는다() async throws {
    do {
      _ = try await ClassRepositoryImpl().fetchMyClasses()
      Issue.record("live 저장소가 서버 연결 없이 클래스 목록을 반환함")
    } catch {
      #expect(ClassError.from(error) == .network("클래스 서버 API가 연결되지 않았습니다."))
    }
  }

  @Test
  func useCase는_주입된_repository를_사용한다() async throws {
    let room = ClassRoom.mocks[0]
    let useCase = withDependencies {
      $0.classRepository = MockClassRepository(rooms: [room], availableRooms: [])
    } operation: {
      ClassUseCaseImpl()
    }

    #expect(try await useCase.fetchMyClasses() == [room])
  }

  @Test
  func 생성한_클래스는_목록에_추가되고_선생님_역할을_갖는다() async throws {
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    let created = try await repository.createClass(
      ClassCreation(
        name: "토론 수업",
        deadline: Date(timeIntervalSince1970: 1_800_000_000),
        battleId: 101,
        allowsAnonymousOpinion: true,
        requiresComment: false
      )
    )

    #expect(created.role == .owner)
    #expect(created.battle.id == 101)
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

  @Test
  func 추천_배틀은_수준과_카테고리와_검색어로_걸러진다() async throws {
    let repository = MockClassRepository()
    let middle = try await repository.fetchRecommendedBattles(
      filter: .init(keyword: "소년", level: .middle, category: .society)
    )
    let high = try await repository.fetchRecommendedBattles(
      filter: .init(level: .high, category: .society)
    )
    let philosophy = try await repository.fetchRecommendedBattles(
      filter: .init(level: .middle, category: .philosophy)
    )

    #expect(middle.map(\.id) == [101])
    #expect(high.isEmpty)
    #expect(philosophy.count == 8)
    #expect(philosophy.first?.title == "인간은 본래 선한가, 악한가?")
  }

  @Test
  func 마감일_변경은_목록과_참여코드_조회에_반영된다() async throws {
    let repository = MockClassRepository(rooms: [ClassRoom.mocks[0]], availableRooms: [])
    let deadline = Date(timeIntervalSince1970: 1_801_000_000)

    let updated = try await repository.updateDeadline(id: 1, deadline: deadline)

    #expect(updated.deadline == deadline)
    #expect(try await repository.fetchMyClasses()[0].deadline == deadline)
    #expect(try await repository.fetchClass(joinCode: updated.joinCode).deadline == deadline)
  }

  @Test
  func 클래스_삭제는_목록과_참여코드_조회에_반영된다() async throws {
    let repository = MockClassRepository(rooms: [ClassRoom.mocks[0]], availableRooms: [])

    try await repository.deleteClass(id: 1)

    #expect(try await repository.fetchMyClasses().isEmpty)
    do {
      _ = try await repository.fetchClass(joinCode: "PK7M2Q")
      Issue.record("삭제한 클래스를 조회할 수 있음")
    } catch {
      #expect(ClassError.from(error) == .invalidCode)
    }
  }

  @Test
  func 목_멤버는_클래스_인원수와_일치하고_운영자를_포함한다() async throws {
    let repository = MockClassRepository()
    for room in ClassRoom.mocks + [.mockJoinable] {
      let members = try await repository.fetchMembers(roomID: room.id)
      #expect(members.count == room.memberCount)
      #expect(members.first?.id == 1)
      #expect(members.first?.isOwner == true)
    }
  }

  @Test
  func 생성과_참여는_같은_actor의_멤버와_인원수를_갱신한다() async throws {
    let repository = MockClassRepository(rooms: [], availableRooms: [.mockJoinable])
    let created = try await repository.createClass(
      ClassCreation(
        name: "새 클래스",
        deadline: Date(timeIntervalSince1970: 1_800_000_000),
        battleId: 101,
        allowsAnonymousOpinion: true,
        requiresComment: false
      )
    )
    #expect(try await repository.fetchMembers(roomID: created.id).count == 1)
    #expect(try await repository.currentMemberID(roomID: created.id) == 1)

    let joined = try await repository.joinClass(joinCode: "PK9T3S", nickname: "민지")
    let members = try await repository.fetchMembers(roomID: joined.id)
    #expect(members.count == joined.memberCount)
    #expect(members.last?.name == "민지")
    #expect(try await repository.currentMemberID(roomID: joined.id) == members.last?.id)
  }

  @Test
  func 목_멤버_제거는_운영자만_가능하고_목록과_마감일_변경에도_인원수가_유지된다() async throws {
    let repository = MockClassRepository(rooms: [ClassRoom.mocks[0]], availableRooms: [])
    let updated = try await repository.removeMember(roomID: 1, memberID: 2, currentMemberID: 1)
    #expect(updated.memberCount == ClassRoom.mocks[0].memberCount - 1)
    #expect(try await repository.fetchMembers(roomID: 1).count == updated.memberCount)
    #expect(try await repository.fetchMyClasses()[0].memberCount == updated.memberCount)

    let deadline = try await repository.updateDeadline(id: 1, deadline: Date(timeIntervalSince1970: 1_801_000_000))
    #expect(deadline.memberCount == updated.memberCount)
    #expect(try await repository.fetchClass(joinCode: updated.joinCode).memberCount == updated.memberCount)

    for (memberID, currentMemberID) in [(1, 1), (3, 3), (3, 2)] {
      do {
        _ = try await repository.removeMember(roomID: 1, memberID: memberID, currentMemberID: currentMemberID)
        Issue.record("권한 없는 멤버 제거가 허용됨")
      } catch {
        #expect(ClassError.from(error) != .invalidCode)
      }
    }
  }

  @Test
  func 목_이름_수정은_본인에게만_허용된다() async throws {
    let repository = MockClassRepository(rooms: [ClassRoom.mocks[0]], availableRooms: [])
    let renamed = try await repository.updateDisplayName(
      roomID: 1, memberID: 1, currentMemberID: 1, name: " 김 선생님 "
    )
    #expect(renamed.name == "김 선생님")
    #expect(try await repository.fetchMembers(roomID: 1).first?.name == "김 선생님")

    do {
      _ = try await repository.updateDisplayName(roomID: 1, memberID: 2, currentMemberID: 1, name: "다른 이름")
      Issue.record("다른 멤버의 이름 수정이 허용됨")
    } catch {
      #expect(ClassError.from(error) != .invalidCode)
    }
  }

  @Test
  func 성인_추천_배틀을_조회할_수_있다() async throws {
    let repository = MockClassRepository()
    let battles = try await repository.fetchRecommendedBattles(filter: .init(level: .adult))
    #expect(battles.map(\.id) == [103])
  }
}
