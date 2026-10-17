//
//  ClassDetailTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI
import Testing

@MainActor
struct ClassDetailTests {
  @Test
  func 목_저장소가_있으면_배틀에_입장한다() async {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    } withDependencies: {
      $0.classMockRepository = repository
    }

    await store.send(.view(.battleTapped))
    await store.receive(\.delegate, .openBattle(room))
  }

  @Test
  func 참여하지_않는_운영자는_배틀_진입만_제한되고_관리는_가능하다() async {
    let source = ClassRoom.mocks[0]
    let room = ClassRoom(
      id: source.id,
      name: source.name,
      joinCode: source.joinCode,
      battle: source.battle,
      deadline: source.deadline,
      memberCount: source.memberCount,
      role: source.role,
      status: source.status,
      allowsAnonymousOpinion: source.allowsAnonymousOpinion,
      requiresComment: source.requiresComment,
      ownerParticipates: false,
      memberCapacity: source.memberCapacity
    )
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    } withDependencies: {
      $0.classMockRepository = repository
    }

    #expect(store.state.canParticipateInBattle == false)
    await store.send(.view(.battleTapped))
    await store.send(.view(.managementTapped)) {
      $0.modal = .init(kind: .management)
    }
    await store.send(.view(.reportTapped))
    await store.receive(\.delegate, .openReport(room))
  }

  @Test
  func 선생님은_관리_모달을_닫고_마감일_편집을_상위에_요청한다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.view(.managementTapped)) {
      $0.modal = .init(kind: .management)
    }
    await store.send(.view(.deadlineTapped)) {
      $0.modal = nil
    }
    await store.receive(\.delegate, .openDeadline(room))
  }

  @Test
  func 학생은_마감일과_삭제_동작을_사용할_수_없다() async {
    let store = TestStore(initialState: ClassDetailFeature.State(room: ClassRoom.mockJoinable)) {
      ClassDetailFeature()
    }

    await store.send(.view(.deadlineTapped))
    await store.send(.view(.deleteTapped))
  }

  @Test
  func 목_배틀을_누르면_준비_안내를_표시한다() async {
    for room in ClassRoom.mocks where room.status == .open {
      let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
        ClassDetailFeature()
      }

      await store.send(.view(.battleTapped)) {
        $0.customAlert = .alert(
          title: "배틀을 준비하고 있어요",
          message: "이 클래스의 배틀은 아직 참여할 수 없어요."
        )
      }
      await store.send(.customAlert(.presented(.confirmTapped))) {
        $0.customAlert = nil
      }
    }
  }

  @Test
  func 마감된_클래스는_라이브_배틀_대신_결과_진입_화면을_연다() async {
    let room = ClassRoom.mockClosedSociety
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.view(.battleTapped))
    await store.receive(\.delegate, .openClosedBattle(room))
  }

  @Test
  func 마감된_운영자_배틀_카드도_결과_진입_화면을_연다() async {
    let room = ClassRoom.mocks[2]
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.view(.battleTapped))
    await store.receive(\.delegate, .openClosedBattle(room))

    await store.send(.view(.reportTapped))
    await store.receive(\.delegate, .openReport(room))
  }

  @Test
  func AI_목_배틀도_클래스_화면으로_진입한다() async {
    let original = ClassRoom.mocks[0]
    let battle = ClassBattleSummary(
      id: -1,
      title: "AI 추천 질문",
      summary: "목 콘텐츠",
      philosopherA: "첫 번째 근거",
      optionATitle: "찬성",
      philosopherB: "두 번째 근거",
      optionBTitle: "반대",
      category: .philosophy,
      level: .middle,
      audioDuration: 0,
      viewCount: 0
    )
    let room = ClassRoom(
      id: original.id,
      name: original.name,
      joinCode: original.joinCode,
      battle: battle,
      deadline: original.deadline,
      memberCount: original.memberCount,
      role: original.role,
      status: original.status,
      allowsAnonymousOpinion: original.allowsAnonymousOpinion,
      requiresComment: original.requiresComment,
      memberCapacity: original.memberCapacity
    )
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    } withDependencies: {
      $0.classMockRepository = repository
    }

    await store.send(.view(.battleTapped))
    await store.receive(\.delegate, .openBattle(room))
  }

  @Test
  func 결과보기를_누르면_현재_클래스를_리포트로_전달한다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.view(.reportTapped))
    await store.receive(\.delegate, .openReport(room))
  }

  @Test
  func 멤버_변경_뒤_상세_인원수를_동기화한다() async {
    let room = ClassRoom.mocks[0]
    let updated = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: room.deadline,
      memberCount: room.memberCount - 1,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment,
      memberCapacity: room.memberCapacity
    )
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.dataUpdated(updated)) {
      $0.room = updated
    }
  }

  @Test
  func 변경된_마감일은_상세_표시에_반영된다() async {
    let room = ClassRoom.mocks[0]
    let updated = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: .distantFuture,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment,
      ownerParticipates: room.ownerParticipates,
      memberCapacity: room.memberCapacity
    )
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.dataUpdated(updated)) {
      $0.room = updated
    }
    #expect(store.state.deadlineText == "마감일 없음")
  }

  @Test
  func 삭제가_완료된_뒤에만_화면을_닫는다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.view(.deleteTapped)) {
      $0.customAlert = CustomAlertState(
        title: "삭제 후에는 복구할 수 없어요.\n그럼에도 삭제하시겠습니까?",
        confirmTitle: "삭제하기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
    }
    await store.send(.view(.deleteConfirmed)) {
      $0.customAlert = nil
    }
    await store.receive(\.async, .delete(room.id)) {
      $0.isLoading = true
    }
    await store.receive(\.inner, .deleted(room.id, nil)) {
      $0.isLoading = false
    }
    await store.receive(\.delegate, .deleted(room.id))
  }
}
