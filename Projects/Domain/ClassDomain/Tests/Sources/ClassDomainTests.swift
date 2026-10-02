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

    #expect(middle.map(\.id) == [101])
    #expect(high.isEmpty)
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
}
