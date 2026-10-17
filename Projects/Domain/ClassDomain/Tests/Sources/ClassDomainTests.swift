//
//  ClassDomainTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/11/26.
//

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
    #expect(created.memberCapacity == nil)
    #expect(created.battle.id == 101)
    #expect(try await repository.fetchMyClasses() == [created])
    #expect(try await repository.fetchClass(joinCode: created.joinCode) == created)
  }

  @Test
  func 운영자_참여_선택은_저장과_수정_뒤에도_유지되고_멤버_권한은_유지된다() async throws {
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    let deadline = Date(timeIntervalSince1970: 1_800_000_000)
    let creation = ClassCreation(
      name: "토론 수업",
      deadline: deadline,
      battleId: 101,
      allowsAnonymousOpinion: false,
      requiresComment: false,
      ownerParticipates: false
    )
    let created = try await repository.createClass(creation)
    #expect(created.ownerParticipates == false)
    #expect(created.role == .owner)
    #expect(created.memberCapacity == nil)
    #expect(created.memberCount == 1)
    #expect(try await repository.fetchMembers(roomID: created.id).first?.isOwner == true)
    #expect(try await repository.currentMemberID(roomID: created.id) == 1)

    let updated = try await repository.updateDeadline(id: created.id, deadline: deadline.addingTimeInterval(60))
    #expect(updated.ownerParticipates == false)
    #expect(try await repository.fetchClass(joinCode: created.joinCode).ownerParticipates == false)
  }

  @Test
  func AI_목_배틀은_별도_생성_경로로_저장된다() async throws {
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    let source = ClassBattleSummary.mocks[0]
    let battle = ClassBattleSummary(
      id: -1,
      title: "새 AI 질문",
      summary: "설명",
      philosopherA: "A 관점",
      optionATitle: "A",
      philosopherB: "B 관점",
      optionBTitle: "B",
      category: .philosophy,
      level: .middle,
      audioDuration: 0,
      viewCount: 0
    )
    let creation = ClassCreation(
      name: "AI 수업",
      deadline: Date(timeIntervalSince1970: 1_800_000_000),
      battleId: battle.id,
      allowsAnonymousOpinion: false,
      requiresComment: true
    )
    let created = try await repository.createClass(creation, battle: battle)
    #expect(created.battle == battle)
    #expect(created.role == .owner)
    #expect(created.memberCapacity == nil)
    #expect(try await repository.fetchMyClasses() == [created])
    #expect(try await repository.fetchClass(joinCode: created.joinCode) == created)

    var mismatched = creation
    mismatched.battleId = source.id
    do {
      _ = try await repository.createClass(mismatched, battle: battle)
      Issue.record("다른 배틀 ID로 생성됨")
    } catch {
      #expect(try await repository.fetchMyClasses() == [created])
    }
  }

  @Test(arguments: [nil, 30] as [Int?])
  func 참여하면_학생_역할로_목록에_추가되고_중복_참여는_거부한다(memberCapacity: Int?) async throws {
    let room = copyRoom(ClassRoom.mockJoinable, memberCapacity: memberCapacity)
    let repository = MockClassRepository(rooms: [], availableRooms: [room])
    let joined = try await repository.joinClass(joinCode: "PK9T3S", nickname: "민지")

    #expect(joined.role == .member)
    #expect(joined.memberCount == room.memberCount + 1)
    #expect(joined.memberCapacity == memberCapacity)
    #expect(try await repository.fetchMyClasses() == [joined])
    #expect(try await repository.fetchClass(joinCode: room.joinCode).memberCapacity == memberCapacity)
    do {
      _ = try await repository.joinClass(joinCode: "PK9T3S", nickname: "민지")
      Issue.record("중복 참여가 허용됨")
    } catch {
      #expect(ClassError.from(error) == .alreadyJoined)
    }
    try await repository.leaveClass(id: room.id)
    #expect(try await repository.fetchMyClasses().isEmpty)
    let available = try await repository.fetchClass(joinCode: room.joinCode)
    #expect(available.memberCapacity == memberCapacity)
    #expect(available.memberCount == room.memberCount)
    #expect(try await repository.fetchMembers(roomID: room.id).map(\.id) == Array(1 ... room.memberCount))
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
  func 여러_카테고리_중_하나에_속한_배틀을_추천한다() async throws {
    let repository = MockClassRepository()
    let battles = try await repository.fetchRecommendedBattles(
      filter: .init(level: .middle, categories: [.society, .literature])
    )

    #expect(battles.map(\.id) == [101, 105])
  }

  @Test(arguments: [nil, 30] as [Int?])
  func 마감일_변경은_목록과_참여코드_조회에_반영된다(memberCapacity: Int?) async throws {
    let room = copyRoom(ClassRoom.mocks[0], memberCapacity: memberCapacity)
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let deadline = Date(timeIntervalSince1970: 1_801_000_000)

    let updated = try await repository.updateDeadline(id: 1, deadline: deadline)

    #expect(updated.deadline == deadline)
    #expect(updated.memberCapacity == memberCapacity)
    #expect(try await repository.fetchMyClasses()[0].deadline == deadline)
    #expect(try await repository.fetchMyClasses()[0].memberCapacity == memberCapacity)
    #expect(try await repository.fetchClass(joinCode: updated.joinCode).deadline == deadline)
    #expect(try await repository.fetchClass(joinCode: updated.joinCode).memberCapacity == memberCapacity)
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
  func 기본_클래스_멤버는_디자인의_표시_이름으로_시작한다() async throws {
    let members = try await MockClassRepository().fetchMembers(roomID: ClassRoom.mocks[0].id)

    #expect(members.prefix(10).map(\.name) == [
      "김선생", "공은지", "권동현", "김민지", "천다올", "유시영", "주천수", "김예은", "서원지", "현준혁",
    ])
    let avatars: [ClassMemberAvatar?] = [
      .lion, .koala, .bear, .penguin, .dog, .sloth, .alpaca, .fox, .hamster, .raccoon,
    ]
    #expect(members.prefix(10).map(\.avatar) == avatars)
  }

  @Test(arguments: [nil, 30] as [Int?])
  func 주입한_멤버는_인원수와_다음_ID에_반영되고_알_수_없는_방은_무시한다(memberCapacity: Int?) async throws {
    let room = copyRoom(ClassRoom.mockJoinable, memberCapacity: memberCapacity)
    let repository = MockClassRepository(
      rooms: [],
      availableRooms: [room],
      members: [
        room.id: [
          ClassMember(id: 1, name: "운영자", isOwner: true),
          ClassMember(id: 37, name: "기존 참여자", avatar: .koala),
        ],
        999: [ClassMember(id: 1, name: "무관한 방", isOwner: true)],
      ]
    )

    #expect(try await repository.fetchClass(joinCode: room.joinCode).memberCount == 2)
    #expect(try await repository.fetchClass(joinCode: room.joinCode).memberCapacity == memberCapacity)
    let joined = try await repository.joinClass(joinCode: room.joinCode, nickname: "새 참여자")
    #expect(joined.memberCount == 3)
    #expect(joined.memberCapacity == memberCapacity)
    #expect(try await repository.currentMemberID(roomID: room.id) == 38)
    #expect(try await repository.fetchMembers(roomID: room.id).map(\.id) == [1, 37, 38])
    #expect(try await repository.fetchMembers(roomID: room.id).first(where: { $0.id == 37 })?.avatar == .koala)
    do {
      _ = try await repository.fetchMembers(roomID: 999)
      Issue.record("알 수 없는 방의 멤버를 반환했습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }
    try await repository.leaveClass(id: room.id)
    let available = try await repository.fetchClass(joinCode: room.joinCode)
    #expect(available.memberCapacity == memberCapacity)
    #expect(available.memberCount == 2)
    #expect(try await repository.fetchMembers(roomID: room.id).map(\.id) == [1, 37])
    #expect(try await repository.fetchMembers(roomID: room.id).last?.avatar == .koala)
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
    #expect(created.memberCapacity == nil)
    #expect(try await repository.currentMemberID(roomID: created.id) == 1)

    let joined = try await repository.joinClass(joinCode: "PK9T3S", nickname: "민지")
    let members = try await repository.fetchMembers(roomID: joined.id)
    #expect(members.count == joined.memberCount)
    #expect(members.last?.name == "민지")
    #expect(try await repository.currentMemberID(roomID: joined.id) == members.last?.id)
  }

  @Test(arguments: [nil, 30] as [Int?])
  func 목_멤버_제거는_운영자만_가능하고_목록과_마감일_변경에도_인원수가_유지된다(memberCapacity: Int?) async throws {
    let room = copyRoom(ClassRoom.mocks[0], memberCapacity: memberCapacity)
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let updated = try await repository.removeMember(roomID: 1, memberID: 2, currentMemberID: 1)
    #expect(updated.memberCount == room.memberCount - 1)
    #expect(updated.memberCapacity == memberCapacity)
    #expect(try await repository.fetchMembers(roomID: 1).count == updated.memberCount)
    #expect(try await repository.fetchMembers(roomID: 1).first?.avatar == .lion)
    #expect(try await repository.fetchMyClasses()[0].memberCount == updated.memberCount)
    #expect(try await repository.fetchMyClasses()[0].memberCapacity == memberCapacity)

    let deadline = try await repository.updateDeadline(id: 1, deadline: Date(timeIntervalSince1970: 1_801_000_000))
    #expect(deadline.memberCount == updated.memberCount)
    #expect(deadline.memberCapacity == memberCapacity)
    #expect(try await repository.fetchClass(joinCode: updated.joinCode).memberCount == updated.memberCount)
    #expect(try await repository.fetchClass(joinCode: updated.joinCode).memberCapacity == memberCapacity)

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

  private func copyRoom(
    _ room: ClassRoom,
    memberCapacity: Int?
  ) -> ClassRoom {
    ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: room.deadline,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment,
      ownerParticipates: room.ownerParticipates,
      memberCapacity: memberCapacity
    )
  }
}
