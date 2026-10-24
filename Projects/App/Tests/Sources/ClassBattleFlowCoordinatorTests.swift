import ClassDomainInterface
import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
@testable import Picke
import TCAFlow
import Testing

@MainActor
struct ClassBattleFlowCoordinatorTests {
  @Test
  func TTS_클래스는_Mock_주입과_무관하게_배틀_Flow로_진입하고_상세로_돌아온다() async {
    let room = ClassRoom.mocks[0]
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classMockRepository = MockClassRepository(rooms: [room])
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openBattle(room)))
    )))
    guard case let .battleFlow(flow)? = store.state.routes.last?.screen else {
      Issue.record("TTS 배틀 Flow가 열리지 않았습니다")
      return
    }
    #expect(flow.room.id == room.id)

    await store.send(.router(.routeAction(
      id: 2,
      action: .battleFlow(.delegate(.completed(classID: room.id)))
    )))
    #expect(store.state.routes.count == 2)
    guard case let .detail(detail)? = store.state.routes.last?.screen else {
      Issue.record("배틀 완료 후 상세로 돌아오지 않았습니다")
      return
    }
    #expect(detail.room.id == room.id)
  }

  @Test
  func CUSTOM_클래스는_Mock_주입과_무관하게_클래스_API_사전투표로_진입한다() async {
    let original = ClassRoom.mocks[0]
    let room = ClassRoom(
      id: original.id,
      name: original.name,
      joinCode: original.joinCode,
      battle: original.battle,
      deadline: original.deadline,
      memberCount: original.memberCount,
      role: original.role,
      status: original.status,
      allowsAnonymousOpinion: original.allowsAnonymousOpinion,
      requiresComment: true,
      battleType: .custom
    )
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classMockRepository = MockClassRepository(rooms: [room])
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openBattle(room)))
    )))
    guard case let .aiVote(vote)? = store.state.routes.last?.screen else {
      Issue.record("클래스 API 사전투표가 열리지 않았습니다")
      return
    }
    #expect(vote.isLiveClassBattle)
    #expect(!vote.isPostVote)
    #expect(vote.battleID == room.battle.id)
  }
}
