@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI
import Testing

@MainActor
struct ClassDetailTests {
  @Test
  func 선생님은_마감일을_수정할_수_있다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }
    let updated = room.deadline.addingTimeInterval(86400)

    await store.send(.view(.deadlineTapped)) {
      $0.modal = .init(kind: .deadline)
    }
    await store.send(.binding(.set(\.draftDeadline, updated))) {
      $0.draftDeadline = updated
    }
    await store.send(.view(.deadlineSaved))
    await store.receive(\.async, .updateDeadline(room.id, updated)) {
      $0.isLoading = true
    }
    let updatedRoom = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: updated,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment
    )
    await store.receive(\.inner, .deadlineUpdated(.success(updatedRoom))) {
      $0.isLoading = false
      $0.room = updatedRoom
      $0.deadline = updated
      $0.modal = nil
    }
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
    for room in ClassRoom.mocks {
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
      requiresComment: room.requiresComment
    )
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.dataUpdated(updated)) {
      $0.room = updated
    }
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
