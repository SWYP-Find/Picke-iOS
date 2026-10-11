//
//  MyClassTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import PickeSharedUI
import Testing

@MainActor
struct MyClassTests {
  @Test
  func 진행_상태로_필터링한다() async {
    var state = MyClassFeature.State()
    state.rooms = ClassRoom.mocks
    let store = TestStore(initialState: state) {
      MyClassFeature()
    }

    await store.send(.view(.progressTapped(.closed))) {
      $0.progress = .closed
    }
    #expect(store.state.visibleRooms.map(\.id) == [3])

    await store.send(.view(.progressTapped(.open))) {
      $0.progress = .open
    }
    #expect(store.state.visibleRooms.map(\.id) == [1, 2])
    #expect(ClassRoom.mocks.allSatisfy { $0.role == .owner })
    #expect(ClassRoom.mockJoinable.role == .member)
  }

  @Test
  func 클래스를_누르면_해당_방을_델리게이트로_전달한다() async {
    var state = MyClassFeature.State()
    state.rooms = ClassRoom.mocks
    let store = TestStore(initialState: state) {
      MyClassFeature()
    }

    await store.send(.view(.roomTapped(1)))
    await store.receive(\.delegate, .openRoom(ClassRoom.mocks[0]))
  }

  @Test
  func 카드_더보기는_목록_위에_기존_관리_모달을_연다() async {
    var state = MyClassFeature.State()
    state.rooms = ClassRoom.mocks
    let store = TestStore(initialState: state) {
      MyClassFeature()
    }

    await store.send(.view(.managementTapped(1))) {
      $0.selectedRoomID = 1
      $0.modal = .init(kind: .management)
    }
    await store.send(.view(.leaveTapped))
    await store.send(.view(.managementDismissed)) {
      $0.modal = nil
    }
    #expect(store.state.rooms.count == 3)
  }

  @Test
  func 운영자_관리_메뉴의_수정_경로와_권한_검사를_유지한다() async {
    var state = MyClassFeature.State()
    state.rooms = [ClassRoom.mocks[0], .mockJoinable]
    let store = TestStore(initialState: state) { MyClassFeature() }

    await store.send(.view(.managementTapped(999)))
    await store.send(.view(.managementTapped(1))) {
      $0.selectedRoomID = 1
      $0.modal = .init(kind: .management)
    }
    await store.send(.view(.editClassTapped)) {
      $0.modal = nil
    }
    await store.receive(\.delegate, .openInformation(ClassRoom.mocks[0]))

    await store.send(.view(.managementTapped(ClassRoom.mockJoinable.id))) {
      $0.selectedRoomID = ClassRoom.mockJoinable.id
      $0.modal = .init(kind: .management)
    }
    await store.send(.view(.editClassTapped))
    await store.send(.view(.deleteTapped))
    await store.send(.view(.leaveTapped)) {
      $0.modal = nil
      $0.pendingConfirmation = .leave(ClassRoom.mockJoinable.id)
      $0.customAlert = CustomAlertState(
        title: "클래스에서 나가시겠습니까?",
        message: "나간 후에는 데이터를 복구할 수 없어요.",
        confirmTitle: "나가기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
    }
    await store.send(.customAlert(.presented(.cancelTapped))) {
      $0.customAlert = nil
      $0.pendingConfirmation = nil
    }
    await store.send(.view(.leaveConfirmed))
  }

  @Test
  func 운영자_삭제_확인은_선택한_원래_방에만_적용된다() async {
    var state = MyClassFeature.State()
    state.rooms = ClassRoom.mocks
    state.selectedRoomID = 1
    let store = TestStore(initialState: state) { MyClassFeature() }

    await store.send(.view(.deleteTapped)) {
      $0.pendingConfirmation = .delete(1)
      $0.customAlert = CustomAlertState(
        title: "삭제 후에는 복구할 수 없어요.\n그럼에도 삭제하시겠습니까?",
        confirmTitle: "삭제하기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
    }
    await store.send(.customAlert(.presented(.cancelTapped))) {
      $0.pendingConfirmation = nil
      $0.customAlert = nil
    }
    await store.send(.view(.deleteConfirmed))
    #expect(store.state.rooms.count == 3)
  }

  @Test
  func 운영자_삭제는_확인한_방만_삭제한다() async {
    let repository = MockClassRepository(rooms: ClassRoom.mocks, availableRooms: [])
    var state = MyClassFeature.State()
    state.rooms = ClassRoom.mocks
    state.selectedRoomID = 1
    let store = TestStore(initialState: state) { MyClassFeature() } withDependencies: {
      $0.classUseCase = repository
    }

    await store.send(.view(.deleteTapped)) {
      $0.pendingConfirmation = .delete(1)
      $0.customAlert = CustomAlertState(
        title: "삭제 후에는 복구할 수 없어요.\n그럼에도 삭제하시겠습니까?",
        confirmTitle: "삭제하기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
    }
    await store.send(.view(.managementTapped(2))) {
      $0.selectedRoomID = 2
      $0.modal = .init(kind: .management)
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.customAlert = nil
      $0.pendingConfirmation = nil
      $0.modal = nil
    }
    await store.receive(\.async, .delete(1)) {
      $0.isDeleting = true
      $0.fetchGeneration = 1
    }
    await store.send(.inner(.roomsResponse(0, .success(ClassRoom.mocks))))
    await store.receive(\.inner, .deleted(.success(1))) {
      $0.isDeleting = false
      $0.selectedRoomID = nil
      $0.rooms.removeAll { $0.id == 1 }
    }
    await store.receive(\.async, .fetchRooms) {
      $0.fetchGeneration = 2
      $0.isLoading = true
    }
    await store.receive(\.inner, .roomsResponse(2, .success(Array(ClassRoom.mocks.dropFirst())))) {
      $0.isLoading = false
    }
    await store.send(.inner(.roomsResponse(0, .success(ClassRoom.mocks))))
    #expect(store.state.rooms.map(\.id) == [2, 3])
  }

  @Test
  func 학생은_진행중이거나_종료된_방의_관리_메뉴를_연다() async {
    var state = MyClassFeature.State()
    state.rooms = [.mockJoinable, .mockClosedSociety]
    let store = TestStore(initialState: state) { MyClassFeature() }

    for room in state.rooms {
      await store.send(.view(.managementTapped(room.id))) {
        $0.selectedRoomID = room.id
        $0.modal = .init(kind: .management)
      }
      await store.send(.view(.managementDismissed)) {
        $0.modal = nil
      }
    }
  }

  @Test
  func 탈퇴_확인은_원래_방을_한_번만_처리하고_정리_승인까지_카드를_보존한다() async {
    let room = ClassRoom.mockJoinable
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    var state = MyClassFeature.State()
    state.rooms = [room, .mockClosedSociety]
    state.selectedRoomID = room.id
    let store = TestStore(initialState: state) { MyClassFeature() } withDependencies: {
      $0.classUseCase = repository
    }

    await store.send(.view(.leaveTapped)) {
      $0.pendingConfirmation = .leave(room.id)
      $0.customAlert = CustomAlertState(
        title: "클래스에서 나가시겠습니까?",
        message: "나간 후에는 데이터를 복구할 수 없어요.",
        confirmTitle: "나가기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
    }
    await store.send(.view(.managementTapped(ClassRoom.mockClosedSociety.id))) {
      $0.selectedRoomID = ClassRoom.mockClosedSociety.id
      $0.modal = .init(kind: .management)
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.customAlert = nil
      $0.pendingConfirmation = nil
      $0.modal = nil
    }
    await store.receive(\.async, .leave(room.id)) {
      $0.isLeaving = true
      $0.leavingRoomID = room.id
      $0.fetchGeneration = 1
    }
    await store.send(.view(.leaveConfirmed))
    await store.send(.view(.roomTapped(ClassRoom.mockClosedSociety.id)))
    await store.receive(\.inner, .left(.success(room.id)))
    await store.receive(\.delegate, .left(room.id))
    #expect(store.state.rooms.contains(where: { $0.id == room.id }))
    await store.send(.inner(.roomsResponse(0, .success([room]))))
    await store.send(.inner(.leaveCleanupCompleted(room.id))) {
      $0.rooms = [.mockClosedSociety]
      $0.selectedRoomID = nil
      $0.isLeaving = false
      $0.leavingRoomID = nil
      $0.fetchGeneration = 2
    }
    let remainingRooms = try? await repository.fetchMyClasses()
    #expect((remainingRooms ?? []).map(\.id) == [])
  }

  @Test
  func 탈퇴_실패는_방을_보존하고_재시도할_수_있게_한다() async {
    let room = ClassRoom.mockJoinable
    let repository = MockClassRepository(rooms: [])
    var state = MyClassFeature.State()
    state.rooms = [room]
    state.selectedRoomID = room.id
    let store = TestStore(initialState: state) { MyClassFeature() } withDependencies: {
      $0.classUseCase = repository
    }

    await store.send(.view(.leaveTapped)) {
      $0.pendingConfirmation = .leave(room.id)
      $0.customAlert = CustomAlertState(
        title: "클래스에서 나가시겠습니까?",
        message: "나간 후에는 데이터를 복구할 수 없어요.",
        confirmTitle: "나가기",
        cancelTitle: "뒤로가기",
        isDestructive: true,
        style: .deleteConfirm
      )
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.customAlert = nil
      $0.pendingConfirmation = nil
    }
    await store.receive(\.async, .leave(room.id)) {
      $0.isLeaving = true
      $0.leavingRoomID = room.id
      $0.fetchGeneration = 1
    }
    await store.receive(\.inner, .left(.failure(.invalidCode))) {
      $0.isLeaving = false
      $0.leavingRoomID = nil
      $0.customAlert = .alert(title: "클래스에서 나가지 못했어요", message: ClassError.invalidCode.message)
    }
    #expect(store.state.rooms == [room])
  }

  @Test
  func 로딩_중이고_클래스가_없으면_스켈레톤을_보여주고_실패하면_오류로_바꾼다() {
    var state = MyClassFeature.State()
    state.isLoading = true
    #expect(state.viewState == .loading)

    state.isLoading = false
    state.errorMessage = "error"
    #expect(state.viewState == .error)

    state.rooms = ClassRoom.mocks
    #expect(state.viewState == .loaded(ClassRoom.mocks))
  }
}
