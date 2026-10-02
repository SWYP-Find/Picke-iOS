@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassMemberTests {
  @Test
  func 멤버_내보내기는_서버_연동_전까지_상태를_변경하지_않는다() async {
    let member = ClassMember(id: 2, name: "김민지")
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0], members: [member])) {
      ClassMemberFeature()
    }
    let originalMembers = store.state.members

    await store.send(.view(.removeTapped(member.id)))
    #expect(store.state.members == originalMembers)
  }

  @Test
  func 학생은_다른_멤버를_삭제할_수_없다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[1])) {
      ClassMemberFeature()
    }

    await store.send(.view(.removeTapped(2)))
    #expect(store.state.members.isEmpty)
    #expect(store.state.room.memberCount == ClassRoom.mocks[1].memberCount)
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

    await store.send(.view(.filterTapped)) {
      $0.filter = .init()
    }
    await store.send(.filter(.presented(.sortSelected(.name))))
    await store.send(.filter(.presented(.applyTapped))) {
      $0.filter = nil
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
    }
    #expect(store.state.appliedFilter == .init())
  }
}
