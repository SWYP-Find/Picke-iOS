@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import PickeSharedUI
import Testing

@MainActor
struct ClassMemberTests {
  @Test
  func 운영자는_확인_후에만_다른_멤버를_내보낸다() async {
    let member = ClassMember(id: 2, name: "김민지")
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassMemberFeature.State(room: room, members: [
      ClassMember(id: 1, name: "김선생", isOwner: true), member,
    ])) {
      ClassMemberFeature()
    }

    await store.send(.view(.removeTapped(member.id))) {
      $0.pendingRemovalID = member.id
      $0.customAlert = CustomAlertState(
        title: "김민지님을 클래스에서 내보낼까요?\n한 번 내보내면 되돌릴 수 없어요.",
        confirmTitle: "내보내기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
    }
    #expect(store.state.members.count == 2)
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.pendingRemovalID = nil
      $0.customAlert = nil
      $0.isSaving = true
    }
    await store.receive(\.delegate, .removeMember(roomID: room.id, memberID: member.id, currentMemberID: 1))
  }

  @Test
  func 학생은_다른_멤버를_삭제할_수_없다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(
      room: ClassRoom.mockJoinable,
      members: [ClassMember(id: 1, name: "김선생", isOwner: true), ClassMember(id: 2, name: "김민지")],
      currentMemberID: 2
    )) {
      ClassMemberFeature()
    }

    await store.send(.view(.removeTapped(1)))
    #expect(store.state.customAlert == nil)
  }

  @Test
  func 운영자와_본인_행은_내보낼_수_없다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(
      room: ClassRoom.mocks[0],
      members: [ClassMember(id: 1, name: "김선생", isOwner: true), ClassMember(id: 2, name: "김민지")]
    )) {
      ClassMemberFeature()
    }

    await store.send(.view(.removeTapped(1)))
    await store.send(.view(.removeConfirmed))
  }

  @Test
  func 본인_이름만_수정하고_갱신된_목_자료를_반영한다() async {
    let room = ClassRoom.mockJoinable
    let member = ClassMember(id: 2, name: "김민지")
    let store = TestStore(initialState: ClassMemberFeature.State(
      room: room, members: [member], currentMemberID: 2
    )) {
      ClassMemberFeature()
    }

    await store.send(.view(.editNameTapped(1)))
    await store.send(.view(.editNameTapped(2))) {
      $0.draftName = "김민지"
      $0.editName = .init()
    }
    await store.send(.binding(.set(\.draftName, " 새 이름 "))) {
      $0.draftName = " 새 이름 "
    }
    await store.send(.view(.nameSaved)) {
      $0.isSaving = true
    }
    await store.receive(\.delegate, .updateDisplayName(
      roomID: room.id, memberID: 2, currentMemberID: 2, name: "새 이름"
    ))
    let updated = ClassMember(id: 2, name: "새 이름")
    await store.send(.dataUpdated(room: room, members: [updated])) {
      $0.members = [updated]
      $0.editName = nil
      $0.isSaving = false
    }
  }

  @Test
  func 저장_실패는_프로젝트_안내창으로_보여준다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0])) {
      ClassMemberFeature()
    }

    await store.send(.dataFailed("다시 시도해 주세요.")) {
      $0.errorMessage = "다시 시도해 주세요."
      $0.customAlert = .alert(
        title: "요청을 완료하지 못했어요",
        message: "다시 시도해 주세요."
      )
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.errorMessage = nil
      $0.customAlert = nil
    }
  }

  @Test
  func 멤버_자료가_없으면_인원수만_보존하고_행은_만들지_않는다() {
    let state = ClassMemberFeature.State(room: ClassRoom.mocks[0])

    #expect(state.room.memberCount == ClassRoom.mocks[0].memberCount)
    #expect(state.members.isEmpty)
    #expect(state.visibleMembers.isEmpty)
    #expect(state.viewState == .unavailable)
  }

  @Test
  func 멤버_로딩은_입력한_검색어를_보존한다() async {
    let room = ClassRoom.mocks[0]
    let member = ClassMember(id: 2, name: "김민지")
    let store = TestStore(initialState: ClassMemberFeature.State(room: room)) {
      ClassMemberFeature()
    }

    await store.send(.binding(.set(\.searchText, "김"))) {
      $0.searchText = "김"
    }
    await store.send(.membersLoaded(room: room, members: [member], currentMemberID: 2)) {
      $0.members = [member]
      $0.currentMemberID = 2
    }
    #expect(store.state.searchText == "김")
    #expect(store.state.visibleMembers == [member])
  }

  @Test
  func 검색어에_맞는_멤버만_표시한다() async {
    let members = [
      ClassMember(id: 1, name: "김민지"),
      ClassMember(id: 2, name: "서원지"),
    ]
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0], members: members)) {
      ClassMemberFeature()
    }

    await store.send(.binding(.set(\.searchText, "김민지"))) {
      $0.searchText = "김민지"
    }
    #expect(store.state.visibleMembers == [members[0]])
    #expect(store.state.viewState == .members([members[0]]))

    await store.send(.binding(.set(\.searchText, "없는 이름"))) {
      $0.searchText = "없는 이름"
    }
    #expect(store.state.viewState == .noSearchResults)
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
    )
    await store.send(.filter(.presented(.applyTapped))) {
      $0.filter = nil
      $0.hasAppliedSort = true
    }
    #expect(store.state.appliedFilter.participation == .all)
  }

  @Test
  func 이름순_정렬은_전달된_멤버에_적용된다() async {
    let members = [
      ClassMember(id: 1, name: "서원지"),
      ClassMember(id: 2, name: "김민지"),
    ]
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0], members: members)) {
      ClassMemberFeature()
    }

    #expect(store.state.visibleMembers == members)

    await store.send(.view(.filterTapped)) {
      $0.filter = .init()
    }
    await store.send(.filter(.presented(.sortSelected(.name))))
    await store.send(.filter(.presented(.applyTapped))) {
      $0.filter = nil
      $0.hasAppliedSort = true
    }
    #expect(store.state.visibleMembers == store.state.members.sorted {
      $0.name.localizedStandardCompare($1.name) == .orderedAscending
    })
    await store.send(.view(.filterTapped)) {
      $0.filter = $0.appliedFilter
    }
  }

  @Test
  func 지원하지_않는_필터와_정렬은_선택해도_적용되지_않는다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0])) {
      ClassMemberFeature()
    }

    await store.send(.view(.filterTapped)) {
      $0.filter = .init()
    }
    await store.send(.filter(.presented(.participationSelected(.notParticipated))))
    await store.send(.filter(.presented(.completionSelected(.noComment))))
    await store.send(.filter(.presented(.attendanceSelected(.changed))))
    await store.send(.filter(.presented(.sortSelected(.comments))))
    await store.send(.filter(.presented(.applyTapped))) {
      $0.filter = nil
      $0.hasAppliedSort = true
    }
    #expect(store.state.appliedFilter == .init())
  }
}
