//
//  ClassMemberTests.swift
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
struct ClassMemberTests {
  @Test
  func 운영자_관리_메뉴는_닫기와_편집과_삭제를_전달한다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassMemberFeature.State(
      room: room,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )) { ClassMemberFeature() }

    await store.send(.view(.managementTapped)) { $0.management = .init(kind: .management) }
    await store.send(.view(.managementDismissed)) { $0.management = nil }
    await store.send(.view(.managementTapped)) { $0.management = .init(kind: .management) }
    await store.send(.view(.managementEditTapped)) { $0.management = nil }
    await store.receive(\.delegate, .editClass)
    await store.send(.view(.managementTapped)) { $0.management = .init(kind: .management) }
    await store.send(.view(.managementDeleteTapped)) { $0.management = nil }
    await store.receive(\.delegate, .deleteClass)
  }

  @Test
  func 학생과_저장중인_운영자는_관리_메뉴를_열거나_이동할_수_없다() async {
    let memberStore = TestStore(initialState: ClassMemberFeature.State(
      room: .mockJoinable,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )) { ClassMemberFeature() }
    await memberStore.send(.view(.managementTapped))
    await memberStore.send(.view(.managementEditTapped))
    await memberStore.send(.view(.managementDeleteTapped))
    #expect(memberStore.state.management == nil)

    var saving = ClassMemberFeature.State(room: .mocks[0], instanceID: UUID(), preloadedViewState: .loaded)
    saving.isSaving = true
    let ownerStore = TestStore(initialState: saving) { ClassMemberFeature() }
    await ownerStore.send(.view(.managementTapped))
    await ownerStore.send(.view(.managementEditTapped))
    await ownerStore.send(.view(.managementDeleteTapped))
    #expect(ownerStore.state.management == nil)
  }

  @Test
  func 운영자는_확인_후에만_다른_멤버를_내보낸다() async {
    let member = ClassMember(id: 2, name: "김민지")
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassMemberFeature.State(room: room, members: [
      ClassMember(id: 1, name: "김선생", isOwner: true), member,
    ], instanceID: UUID(), preloadedViewState: .loaded)) {
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
      currentMemberID: 2,
      instanceID: UUID(),
      preloadedViewState: .loaded
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
      members: [ClassMember(id: 1, name: "김선생", isOwner: true), ClassMember(id: 2, name: "김민지")],
      instanceID: UUID(),
      preloadedViewState: .loaded
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
      room: room, members: [member], currentMemberID: 2, instanceID: UUID(), preloadedViewState: .loaded
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
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())) {
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
    let state = ClassMemberFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())

    #expect(state.room.memberCount == ClassRoom.mocks[0].memberCount)
    #expect(state.members.isEmpty)
    #expect(state.visibleMembers.isEmpty)
    #expect(state.viewState == .loading)
  }

  @Test
  func 멤버_로딩은_입력한_검색어를_보존한다() async {
    let room = ClassRoom.mocks[0]
    let member = ClassMember(id: 2, name: "김민지")
    let requestID = UUID()
    let store = TestStore(initialState: ClassMemberFeature.State(room: room, instanceID: UUID())) {
      ClassMemberFeature()
    }

    await store.send(.binding(.set(\.searchText, "김"))) {
      $0.searchText = "김"
    }
    await store.send(.loadingStarted(requestID)) {
      $0.activeLoadRequestID = requestID
      $0.isLoading = true
    }
    await store.send(.membersLoaded(room: room, members: [member], currentMemberID: 2, requestID: requestID)) {
      $0.activeLoadRequestID = nil
      $0.isLoading = false
      $0.members = [member]
      $0.currentMemberID = 2
      $0.viewState = .loaded
    }
    #expect(store.state.searchText == "김")
    #expect(store.state.visibleMembers == [member])
  }

  @Test
  func 첫_멤버_조회는_로딩_뒤에_빈_결과_또는_오류를_구분한다() async {
    let room = ClassRoom.mocks[0]
    let first = UUID()
    let retry = UUID()
    let store = TestStore(initialState: ClassMemberFeature.State(room: room, instanceID: UUID())) {
      ClassMemberFeature()
    }

    #expect(store.state.viewState == .loading)
    await store.send(.loadingStarted(first)) {
      $0.activeLoadRequestID = first
      $0.isLoading = true
    }
    await store.send(.loadFailed(requestID: first, message: "연결 오류")) {
      $0.activeLoadRequestID = nil
      $0.isLoading = false
      $0.loadErrorMessage = "연결 오류"
      $0.viewState = .error
    }
    #expect(store.state.viewState == .error)
    await store.send(.view(.retryTapped))
    await store.receive(\.delegate, .retryMembers(roomID: room.id))
    await store.send(.loadingStarted(retry)) {
      $0.activeLoadRequestID = retry
      $0.isLoading = true
      $0.loadErrorMessage = nil
      $0.viewState = .loading
    }
    #expect(store.state.viewState == .loading)
    await store.send(.membersLoaded(room: room, members: [], currentMemberID: 1, requestID: retry)) {
      $0.activeLoadRequestID = nil
      $0.isLoading = false
      $0.viewState = .empty
    }
    #expect(store.state.viewState == .empty)
  }

  @Test
  func 다시_조회한_뒤_오래된_응답과_멤버_변경_전_응답은_무시한다() async {
    let room = ClassRoom.mocks[0]
    let old = UUID()
    let fresh = UUID()
    let member = ClassMember(id: 2, name: "최신 멤버")
    let store = TestStore(initialState: ClassMemberFeature.State(
      room: room,
      members: [member],
      instanceID: UUID(),
      preloadedViewState: .loaded
    )) { ClassMemberFeature() }

    #expect(store.state.viewState == .loaded)
    await store.send(.loadingStarted(old)) {
      $0.activeLoadRequestID = old
      $0.isLoading = true
    }
    #expect(store.state.viewState == .loaded)
    await store.send(.loadingStarted(fresh)) {
      $0.activeLoadRequestID = fresh
    }
    await store.send(.membersLoaded(room: room, members: [], currentMemberID: 1, requestID: old))
    await store.send(.loadFailed(requestID: old, message: "늦은 오류"))
    #expect(store.state.members == [member])

    await store.send(.dataUpdated(room: room, members: [member])) {
      $0.activeLoadRequestID = nil
      $0.isLoading = false
    }
    await store.send(.membersLoaded(room: room, members: [], currentMemberID: 1, requestID: fresh))
    #expect(store.state.members == [member])
  }

  @Test
  func 검색어에_맞는_멤버만_표시한다() async {
    let members = [
      ClassMember(id: 1, name: "김민지"),
      ClassMember(id: 2, name: "서원지"),
    ]
    let store = TestStore(initialState: ClassMemberFeature.State(
      room: ClassRoom.mocks[0],
      members: members,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )) {
      ClassMemberFeature()
    }

    await store.send(.binding(.set(\.searchText, "김민지"))) {
      $0.searchText = "김민지"
    }
    #expect(store.state.visibleMembers == [members[0]])
    #expect(store.state.viewState == .loaded)

    await store.send(.binding(.set(\.searchText, "없는 이름"))) {
      $0.searchText = "없는 이름"
      $0.viewState = .noSearchResults
    }
    #expect(store.state.viewState == .noSearchResults)

    await store.send(.binding(.set(\.searchText, ""))) {
      $0.searchText = ""
      $0.viewState = .loaded
    }
    #expect(store.state.visibleMembers.count == 2)
  }

  @Test
  func 캐시된_멤버는_새로고침_실패에도_계속_표시한다() async {
    let room = ClassRoom.mocks[0]
    let member = ClassMember(id: 2, name: "김민지")
    let requestID = UUID()
    let store = TestStore(initialState: ClassMemberFeature.State(
      room: room,
      members: [member],
      instanceID: UUID(),
      preloadedViewState: .loaded
    )) { ClassMemberFeature() }

    await store.send(.loadingStarted(requestID)) {
      $0.activeLoadRequestID = requestID
      $0.isLoading = true
    }
    await store.send(.loadFailed(requestID: requestID, message: "연결 오류")) {
      $0.activeLoadRequestID = nil
      $0.isLoading = false
      $0.loadErrorMessage = "연결 오류"
    }
    #expect(store.state.viewState == .loaded)
    #expect(store.state.visibleMembers == [member])
  }

  @Test
  func 참가자_기본_목록은_본인과_운영자를_앞에_두고_나머지_순서를_유지한다() {
    let members = [
      ClassMember(id: 3, name: "권동현"),
      ClassMember(id: 1, name: "김선생", isOwner: true),
      ClassMember(id: 4, name: "김민지"),
      ClassMember(id: 2, name: "공은지"),
    ]
    let state = ClassMemberFeature.State(
      room: .mockJoinable,
      members: members,
      currentMemberID: 2,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )

    #expect(state.visibleMembers.map(\.id) == [2, 1, 3, 4])
    #expect(state.visibleMembers.count == members.count)
  }

  @Test
  func 참가자_검색은_찾은_행만_정렬하고_없는_본인이나_운영자를_추가하지_않는다() {
    var state = ClassMemberFeature.State(
      room: .mockJoinable,
      members: [
        ClassMember(id: 1, name: "김선생", isOwner: true),
        ClassMember(id: 3, name: "김민지"),
        ClassMember(id: 2, name: "공은지"),
      ],
      currentMemberID: 2,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )

    state.searchText = "김"
    #expect(state.visibleMembers.map(\.id) == [1, 3])
    state.searchText = "공"
    #expect(state.visibleMembers.map(\.id) == [2])
  }

  @Test
  func 운영자_기본_순서와_참가자의_명시적_이름순은_유지된다() {
    let members = [
      ClassMember(id: 3, name: "가나다"),
      ClassMember(id: 1, name: "마바사", isOwner: true),
      ClassMember(id: 2, name: "하하하"),
    ]
    let owner = ClassMemberFeature.State(
      room: ClassRoom.mocks[0],
      members: members,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )
    #expect(owner.visibleMembers.map(\.id) == [3, 1, 2])

    var participant = ClassMemberFeature.State(
      room: .mockJoinable,
      members: members,
      currentMemberID: 2,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )
    #expect(participant.visibleMembers.map(\.id) == [2, 1, 3])
    participant.hasAppliedSort = true
    #expect(participant.visibleMembers.map(\.id) == [3, 1, 2])
    participant.appliedFilter.sort = .comments
    #expect(participant.visibleMembers.map(\.id) == [2, 1, 3])
  }

  @Test
  func 본인이_운영자로_표시되어도_같은_ID가_두_번_나오지_않는다() {
    let members = [
      ClassMember(id: 3, name: "다른 참여자"),
      ClassMember(id: 2, name: "본인 운영자", isOwner: true),
      ClassMember(id: 4, name: "또 다른 참여자"),
    ]
    let state = ClassMemberFeature.State(
      room: .mockJoinable,
      members: members,
      currentMemberID: 2,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )

    #expect(state.visibleMembers.map(\.id) == [2, 3, 4])
  }

  @Test
  func 참가자_목_아바타는_운영자_프레임과_독립된_원본을_사용한다() {
    let owner = MockClassRepository.figmaOwnerMembers
    let participant = MockClassRepository.figmaParticipantMembers

    #expect(participant.map(\.id) == owner.map(\.id))
    #expect(participant.map(\.name) == owner.map(\.name))
    #expect(participant[0].avatar == .lion)
    #expect(participant[1].avatar == .koala)
    #expect(participant[2].avatar == .bear)
    #expect(participant[6].avatar == .alpaca)
    #expect(owner[0].avatar == nil)
    #expect(owner[1].avatar == nil)
    #expect(owner[2].avatar == nil)
    #expect(owner[6].avatar == nil)
  }

  @Test
  func 멤버_필터를_열고_선택한_조건을_적용한다() async {
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())) {
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
    let store = TestStore(initialState: ClassMemberFeature.State(
      room: ClassRoom.mocks[0],
      members: members,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )) {
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
    let store = TestStore(initialState: ClassMemberFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())) {
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
