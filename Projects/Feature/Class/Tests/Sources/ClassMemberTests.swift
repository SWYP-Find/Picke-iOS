@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassMemberTests {
  @Test
  func 선생님은_멤버를_선택하고_삭제할_수_있다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0])) {
      ClassMemberFeature()
    }
    let member = store.state.members[1]

    await store.send(.view(.removeTapped(member.id))) {
      $0.selectedMember = member
    }
    await store.send(.view(.removeConfirmed)) {
      $0.members.remove(at: 1)
      $0.selectedMember = nil
    }
    #expect(store.state.members.count == ClassRoom.mocks[0].memberCount - 1)
  }

  @Test
  func 학생은_다른_멤버를_삭제할_수_없다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[1])) {
      ClassMemberFeature()
    }

    await store.send(.view(.removeTapped(2)))
    #expect(store.state.selectedMember == nil)
  }
}
