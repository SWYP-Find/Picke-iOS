@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import PickeSharedUI
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
      $0.customAlert = CustomAlertState(
        title: "\(member.name)님을 클래스에서 내보낼까요?\n한 번 내보내면 되돌릴 수 없어요.",
        confirmTitle: "내보내기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.members.remove(at: 1)
      $0.selectedMember = nil
      $0.customAlert = nil
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

  @Test
  func 검색어에_맞는_멤버만_표시한다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0])) {
      ClassMemberFeature()
    }

    await store.send(.binding(.set(\.searchText, "학생 1"))) {
      $0.searchText = "학생 1"
    }
    #expect(store.state.visibleMembers.allSatisfy { $0.name.contains("학생 1") })
  }

  @Test
  func 멤버_필터를_열고_선택한_조건을_적용한다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0])) {
      ClassMemberFeature()
    }

    await store.send(.view(.filterTapped)) {
      $0.filter = .init()
    }
    await store.send(
      .filter(.presented(.participationSelected(.completed)))
    ) {
      $0.filter?.participation = .completed
    }
    await store.send(.filter(.presented(.applyTapped))) {
      $0.appliedFilter.participation = .completed
      $0.filter = nil
    }
    await store.send(.view(.filterTapped)) {
      $0.filter = $0.appliedFilter
    }
  }
}
