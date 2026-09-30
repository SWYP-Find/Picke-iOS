@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
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
      $0.isDeadlineSheetPresented = true
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
      $0.isDeadlineSheetPresented = false
    }
  }

  @Test
  func 학생은_마감일과_삭제_동작을_사용할_수_없다() async {
    let store = TestStore(initialState: ClassDetailFeature.State(room: ClassRoom.mocks[1])) {
      ClassDetailFeature()
    }

    await store.send(.view(.deadlineTapped))
    await store.send(.view(.deleteTapped))
  }

  @Test
  func 배틀을_누르면_현재_클래스의_배틀을_전달한다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.view(.battleTapped))
    await store.receive(\.delegate, .openBattle(room.battle))
  }

  @Test
  func 삭제가_완료된_뒤에만_화면을_닫는다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassDetailFeature.State(room: room)) {
      ClassDetailFeature()
    }

    await store.send(.view(.deleteTapped)) {
      $0.isDeleteAlertPresented = true
    }
    await store.send(.view(.deleteConfirmed)) {
      $0.isDeleteAlertPresented = false
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
