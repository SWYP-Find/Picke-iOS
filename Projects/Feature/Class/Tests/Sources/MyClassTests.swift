@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct MyClassTests {
  @Test
  func 소유_역할과_진행_상태를_함께_필터링한다() async {
    var state = MyClassFeature.State()
    state.rooms = ClassRoom.mocks
    let store = TestStore(initialState: state) {
      MyClassFeature()
    }

    await store.send(.view(.ownershipTapped(.joined))) {
      $0.ownership = .joined
    }
    await store.send(.view(.progressTapped(.open))) {
      $0.progress = .open
    }
    #expect(store.state.visibleRooms.map(\.id) == [2])
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
}
