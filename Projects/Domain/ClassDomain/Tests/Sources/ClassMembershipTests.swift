//
//  ClassMembershipTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/11/26.
//

import ClassDomain
import ClassDomainInterface
import ComposableArchitecture
import Testing

struct ClassMembershipTests {
  @Test
  func 참여_중복_이름은_공백을_제거해_거부하고_방_상태를_보존한다() async throws {
    let room = ClassRoom.mockJoinable
    let repository = MockClassRepository(rooms: [], availableRooms: [room])
    let membersBefore = try await repository.fetchMembers(roomID: room.id)

    do {
      _ = try await repository.joinClass(joinCode: room.joinCode, nickname: " 참여자 2 ")
      Issue.record("중복 이름으로 참여했습니다")
    } catch {
      #expect(error as? ClassError == .duplicateName)
    }

    #expect(try await repository.fetchMyClasses().isEmpty)
    #expect(try await repository.fetchClass(joinCode: room.joinCode) == room)
    #expect(try await repository.fetchMembers(roomID: room.id) == membersBefore)
    do {
      _ = try await repository.currentMemberID(roomID: room.id)
      Issue.record("거부된 참여자 ID가 생성됐습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }

    let joined = try await repository.joinClass(joinCode: room.joinCode, nickname: " 새 참여자 ")
    #expect(joined.memberCount == membersBefore.count + 1)
    #expect(try await repository.fetchMembers(roomID: room.id).last?.name == "새 참여자")
  }

  @Test
  func 다른_방의_같은_이름은_참여에_사용할_수_있다() async throws {
    let ownerRoom = ClassRoom.mocks[0]
    let joinable = ClassRoom.mockJoinable
    let repository = MockClassRepository(rooms: [ownerRoom], availableRooms: [joinable])

    let joined = try await repository.joinClass(joinCode: joinable.joinCode, nickname: " 김선생 ")

    #expect(joined.id == joinable.id)
    #expect(try await repository.fetchMembers(roomID: joinable.id).last?.name == "김선생")
    #expect(try await repository.fetchMembers(roomID: ownerRoom.id).first?.name == "김선생")
  }

  @Test
  func 이름_변경은_다른_회원의_이름을_거부하고_본인_이름은_허용한다() async throws {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let membersBefore = try await repository.fetchMembers(roomID: room.id)

    do {
      _ = try await repository.updateDisplayName(
        roomID: room.id,
        memberID: 1,
        currentMemberID: 1,
        name: " 공은지 "
      )
      Issue.record("다른 회원의 이름으로 변경했습니다")
    } catch {
      #expect(error as? ClassError == .duplicateName)
    }
    #expect(try await repository.fetchMembers(roomID: room.id) == membersBefore)

    let unchanged = try await repository.updateDisplayName(
      roomID: room.id,
      memberID: 1,
      currentMemberID: 1,
      name: " 김선생 "
    )
    #expect(unchanged == membersBefore[0])
    let renamed = try await repository.updateDisplayName(
      roomID: room.id,
      memberID: 1,
      currentMemberID: 1,
      name: "새 이름"
    )
    #expect(renamed.name == "새 이름")
    #expect(renamed.id == membersBefore[0].id)
    #expect(renamed.isOwner == membersBefore[0].isOwner)
    #expect(membersBefore[0].avatar != nil)
    #expect(renamed.avatar == membersBefore[0].avatar)
    #expect(try await repository.fetchMembers(roomID: room.id).first == renamed)
  }

  @Test(arguments: [nil, .penguin] as [ClassMemberAvatar?])
  func 주입한_운영자_아바타는_이름_변경_뒤에도_유지된다(avatar: ClassMemberAvatar?) async throws {
    let room = ClassRoom.mocks[0]
    let owner = ClassMember(id: 1, name: "김선생", isOwner: true, avatar: avatar)
    let repository = MockClassRepository(
      rooms: [room],
      availableRooms: [],
      members: [room.id: [owner]]
    )

    let renamed = try await repository.updateDisplayName(
      roomID: room.id,
      memberID: 1,
      currentMemberID: 1,
      name: "새 이름"
    )

    #expect(renamed == ClassMember(id: 1, name: "새 이름", isOwner: true, avatar: avatar))
    #expect(try await repository.fetchMembers(roomID: room.id) == [renamed])
    #expect(try await repository.fetchMyClasses().first?.memberCount == 1)
  }

  @Test
  func 종료된_방은_이름이_중복돼도_종료_오류를_반환한다() async throws {
    let room = ClassRoom.mockClosedSociety
    let repository = MockClassRepository(rooms: [], availableRooms: [room])

    do {
      _ = try await repository.joinClass(joinCode: room.joinCode, nickname: "운영자")
      Issue.record("종료된 방에 참여했습니다")
    } catch {
      #expect(error as? ClassError == .closed)
    }
    #expect(try await repository.fetchMembers(roomID: room.id).count == room.memberCount)
    #expect(try await repository.fetchMyClasses().isEmpty)
  }

  @Test
  func 탈퇴는_현재_회원과_개인_리포트만_제거하고_다른_방과_공유_대시보드를_보존한다() async throws {
    let ownerRoom = ClassRoom.mocks[0]
    let memberRoom = ClassRoom.mockClosedSociety
    let repository = MockClassRepository(
      rooms: [ownerRoom, memberRoom],
      availableRooms: [],
      reports: [ownerRoom.id: MockClassReport.figma, memberRoom.id: MockClassReport.figma],
      dashboards: [ownerRoom.id: MockClassOwnerDashboard.figma]
    )
    let leavingID = try await repository.currentMemberID(roomID: memberRoom.id)
    let membersBefore = try await repository.fetchMembers(roomID: memberRoom.id)

    try await repository.leaveClass(id: memberRoom.id)

    #expect(try await repository.fetchMyClasses() == [ownerRoom])
    let remaining = try await repository.fetchMembers(roomID: memberRoom.id)
    #expect(remaining == membersBefore.filter { $0.id != leavingID })
    #expect(try await repository.fetchClass(joinCode: memberRoom.joinCode).memberCount == remaining.count)
    #expect(try await repository.fetchReport(roomID: ownerRoom.id) == MockClassReport.figma)
    #expect(try await repository.fetchOwnerDashboard(roomID: ownerRoom.id) == MockClassOwnerDashboard.figma)
    do {
      _ = try await repository.currentMemberID(roomID: memberRoom.id)
      Issue.record("탈퇴한 회원 ID가 남았습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }
    do {
      _ = try await repository.fetchReport(roomID: memberRoom.id)
      Issue.record("탈퇴한 회원의 개인 리포트를 읽었습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }
  }

  @Test
  func 열린_방에_재참여하면_새_ID와_이름을_얻고_이전_리포트는_복원되지_않는다() async throws {
    let room = ClassRoom.mockJoinable
    let repository = MockClassRepository(rooms: [], availableRooms: [room])
    let first = try await repository.joinClass(joinCode: room.joinCode, nickname: "첫 이름")
    let firstID = try await repository.currentMemberID(roomID: room.id)
    #expect(try await repository.fetchReport(roomID: room.id) == nil)

    try await repository.leaveClass(id: room.id)
    let available = try await repository.fetchClass(joinCode: room.joinCode)
    #expect(available.id == first.id)
    #expect(available.joinCode == first.joinCode)
    #expect(available.battle == first.battle)
    #expect(available.deadline == first.deadline)
    #expect(available.status == first.status)
    #expect(available.allowsAnonymousOpinion == first.allowsAnonymousOpinion)
    #expect(available.requiresComment == first.requiresComment)
    #expect(available.ownerParticipates == first.ownerParticipates)
    #expect(available.memberCount == room.memberCount)

    let rejoined = try await repository.joinClass(joinCode: room.joinCode, nickname: " 새 이름 ")
    let newID = try await repository.currentMemberID(roomID: room.id)
    #expect(newID > firstID)
    #expect(rejoined.memberCount == first.memberCount)
    #expect(try await repository.fetchMyClasses() == [rejoined])
    #expect(try await repository.fetchMembers(roomID: room.id).last == ClassMember(id: newID, name: "새 이름"))
    #expect(try await repository.fetchReport(roomID: room.id) == nil)
    do {
      _ = try await repository.joinClass(joinCode: room.joinCode, nickname: "중복")
      Issue.record("중복 참여가 허용됐습니다")
    } catch {
      #expect(error as? ClassError == .alreadyJoined)
    }
  }

  @Test
  func 종료된_방은_탈퇴할_수_있지만_재참여할_수_없다() async throws {
    let room = ClassRoom.mockClosedSociety
    let repository = MockClassRepository(rooms: [room], availableRooms: [])

    try await repository.leaveClass(id: room.id)

    #expect(try await repository.fetchMyClasses().isEmpty)
    #expect(try await repository.fetchClass(joinCode: room.joinCode).status == .closed)
    do {
      _ = try await repository.joinClass(joinCode: room.joinCode, nickname: "다시 참여")
      Issue.record("종료된 방에 재참여했습니다")
    } catch {
      #expect(error as? ClassError == .closed)
    }
  }

  @Test
  func 운영자와_알_수_없는_방과_두_번째_탈퇴는_상태를_바꾸지_않는다() async throws {
    let owner = ClassRoom.mocks[0]
    let member = ClassRoom.mockClosedSociety
    let repository = MockClassRepository(rooms: [owner, member], availableRooms: [])
    let initialMembers = try await repository.fetchMembers(roomID: owner.id)
    for id in [owner.id, 999] {
      do {
        try await repository.leaveClass(id: id)
        Issue.record("허용되지 않은 방에서 탈퇴했습니다: \(id)")
      } catch {
        #expect(try await repository.fetchMyClasses() == [owner, member])
        #expect(try await repository.fetchMembers(roomID: owner.id) == initialMembers)
        #expect(try await repository.fetchReport(roomID: member.id) == MockClassReport.figma)
      }
    }

    try await repository.leaveClass(id: member.id)
    let afterFirst = try await repository.fetchMembers(roomID: member.id)
    do {
      try await repository.leaveClass(id: member.id)
      Issue.record("두 번째 탈퇴가 허용됐습니다")
    } catch {
      #expect(try await repository.fetchMyClasses() == [owner])
      #expect(try await repository.fetchMembers(roomID: member.id) == afterFirst)
      #expect(try await repository.fetchOwnerDashboard(roomID: owner.id) == MockClassOwnerDashboard.figma)
    }
  }

  @Test
  func 유스케이스는_탈퇴_ID와_오류를_전달하고_라이브_저장소는_미연결_오류를_반환한다() async throws {
    let room = ClassRoom.mockClosedSociety
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let useCase = withDependencies {
      $0.classRepository = repository
    } operation: {
      ClassUseCaseImpl()
    }
    do {
      try await useCase.leaveClass(id: 999)
      Issue.record("유스케이스가 잘못된 ID를 전달하지 않았습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }
    try await useCase.leaveClass(id: room.id)
    #expect(try await repository.fetchMyClasses().isEmpty)
    do {
      try await ClassRepositoryImpl().leaveClass(id: room.id)
      Issue.record("서버 API 없이 라이브 탈퇴가 성공했습니다")
    } catch {
      #expect(error as? ClassError == .network("클래스 서버 API가 연결되지 않았습니다."))
    }
  }
}
