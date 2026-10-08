import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
@testable import Picke
import TCAFlow
import Testing

@MainActor
struct ClassCoordinatorTests {
  @Test
  func 상세_관리_모달을_닫으면_탭바가_다시_보인다() {
    var state = ClassCoordinator.State()
    var detail = ClassDetailFeature.State(room: .mocks[0])
    state.routes.push(.detail(detail))
    #expect(state.showsTabBar)

    detail.modal = .init(kind: .management)
    state.routes[screenAt: 1] = .detail(detail)
    #expect(!state.showsTabBar)

    detail.modal = nil
    state.routes[screenAt: 1] = .detail(detail)
    #expect(state.showsTabBar)

    detail.customAlert = .alert(title: "확인", message: "안내")
    state.routes[screenAt: 1] = .detail(detail)
    #expect(!state.showsTabBar)
  }

  @Test
  func 멤버_화면의_필터와_이름_시트에서_탭바를_숨긴다() {
    var state = ClassCoordinator.State()
    var members = ClassMemberFeature.State(room: .mocks[0])
    state.routes.push(.members(members))
    #expect(state.showsTabBar)

    members.filter = .init()
    state.routes[screenAt: 1] = .members(members)
    #expect(!state.showsTabBar)

    members.filter = nil
    members.editName = .init()
    state.routes[screenAt: 1] = .members(members)
    #expect(!state.showsTabBar)

    members.editName = nil
    state.routes[screenAt: 1] = .members(members)
    #expect(state.showsTabBar)

    members.customAlert = .alert(title: "확인", message: "안내")
    state.routes[screenAt: 1] = .members(members)
    #expect(!state.showsTabBar)
  }

  @Test
  func 내_클래스_관리_모달도_탭바를_숨긴다() {
    var state = ClassCoordinator.State()
    var myClasses = MyClassFeature.State()
    state.routes.push(.myClasses(myClasses))
    #expect(state.showsTabBar)

    myClasses.modal = .init(kind: .management)
    state.routes[screenAt: 1] = .myClasses(myClasses)
    #expect(!state.showsTabBar)

    myClasses.modal = nil
    state.routes[screenAt: 1] = .myClasses(myClasses)
    #expect(state.showsTabBar)
  }

  @Test
  func 마감_배틀_결과_화면에서는_탭바를_숨긴다() {
    var state = ClassCoordinator.State()
    state.routes.push(.closedBattle(.init(room: .mockClosedSociety)))
    #expect(!state.showsTabBar)
  }

  @Test
  func 마감된_멤버_배틀은_결과_진입과_리포트로_연결된다() async {
    let room = ClassRoom.mockClosedSociety
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openClosedBattle(room)))
    )))
    guard case .closedBattle? = store.state.routes.last?.screen else {
      Issue.record("마감 배틀 결과 진입 화면이 열리지 않음")
      return
    }
    #expect(!store.state.showsTabBar)

    await store.send(.router(.routeAction(
      id: 2,
      action: .closedBattle(.delegate(.openReport(room)))
    )))
    guard case .report? = store.state.routes.last?.screen else {
      Issue.record("멤버 리포트로 이동하지 않음")
      return
    }
  }

  @Test
  func 마감_배틀_화면의_뒤로가기는_클래스_상세로_돌아온다() async {
    let room = ClassRoom.mockClosedSociety
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.closedBattle(.init(room: room)))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 2,
      action: .closedBattle(.delegate(.dismiss))
    )))
    await store.receive {
      guard case .view(.backAction) = $0 else { return false }
      return true
    }
    guard case .detail? = store.state.routes.last?.screen else {
      Issue.record("클래스 상세로 돌아오지 않음")
      return
    }
  }

  @Test
  func 마감된_운영자_결과는_요약으로_직접_이동한다() async {
    let room = ClassRoom.mocks[2]
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openReport(room)))
    )))
    guard case .ownerDashboard? = store.state.routes.last?.screen else {
      Issue.record("운영자 요약으로 이동하지 않음")
      return
    }
  }

  @Test
  func 공유_목_저장소의_멤버_제거를_목록과_상세와_멤버에_전달한다() async throws {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let originalMembers = try await repository.fetchMembers(roomID: room.id)
    let updatedRoom = try await repository.removeMember(roomID: room.id, memberID: 2, currentMemberID: 1)
    let updatedMembers = try await repository.fetchMembers(roomID: room.id)

    var myClasses = MyClassFeature.State()
    myClasses.rooms = [room]
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(myClasses))
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.members(.init(room: room, members: originalMembers)))

    let store = TestStore(initialState: state) {
      ClassCoordinator()
    } withDependencies: {
      $0.classRepository = repository
      $0.classUseCase = ClassUseCaseImpl()
      $0.classMockRepository = repository
    }
    store.exhaustivity = .off

    await store.send(.inner(.memberMutationCompleted(updatedRoom, updatedMembers)))
    await store.finish()

    guard case let .myClasses(list) = store.state.routes[1].screen,
          case let .detail(detail) = store.state.routes[2].screen,
          case let .members(members) = store.state.routes[3].screen
    else {
      Issue.record("클래스 화면 경로가 유지되지 않음")
      return
    }
    #expect(list.rooms[0].memberCount == updatedMembers.count)
    #expect(detail.room.memberCount == updatedMembers.count)
    #expect(members.room.memberCount == updatedMembers.count)
    #expect(members.members.count == updatedMembers.count)
  }
}
