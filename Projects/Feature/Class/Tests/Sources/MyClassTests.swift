@testable import Class
import ClassDomainInterface
import ComposableArchitecture
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
    await store.send(.view(.managementDismissed)) {
      $0.modal = nil
    }
    #expect(store.state.rooms.count == 3)
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
