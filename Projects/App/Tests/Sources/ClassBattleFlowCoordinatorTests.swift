import BattleDomainInterface
import ClassDomainInterface
import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
@testable import Picke
import TCAFlow
import Testing

@MainActor
private func testDetailState(room: ClassRoom) -> ClassDetailFeature.State {
  withDependencies {
    $0.uuid = .incrementing
  } operation: {
    ClassDetailFeature.State(room: room)
  }
}

@MainActor
struct ClassBattleFlowCoordinatorTests {
  @Test
  func 클래스_탭은_주입된_배틀_의존성을_Mock_세션으로_덮어쓰지_않는다() async {
    let room = ClassRoom.mocks[0]
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    state.classState.routes.push(.chat(.init(route: .preVote(battleId: battleID))))
    let store = TestStore(initialState: state) { MainTabCoordinator() } withDependencies: {
      $0.classMockChatSession = session
      $0.battleUseCase = MockBattleRepository()
    }
    store.exhaustivity = .off

    await store.send(.classroom(.router(.routeAction(
      id: 1,
      action: .chat(.router(.routeAction(id: 0, action: .preVote(.async(.fetchBattleDetail)))))
    ))))
    await store.finish()
    await store.skipReceivedActions()

    guard case let .chat(chat)? = store.state.classState.routes.last?.screen,
          case let .preVote(vote)? = chat.routes.last?.screen,
          let detail = vote.battleDetail
    else {
      Issue.record("주입된 배틀 의존성의 응답을 받지 못했습니다")
      return
    }
    #expect(detail.battleInfo.battleId == 0)
  }

  @Test
  func TTS_클래스는_Mock_주입과_무관하게_배틀_Flow로_진입하고_리포트로_이동한다() async {
    let room = ClassRoom.mocks[0]
    var state = ClassCoordinator.State()
    state.routes.push(.detail(testDetailState(room: room)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classMockRepository = MockClassRepository(rooms: [room])
      $0.uuid = .incrementing
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
    #expect(flow.room?.id == room.id)

    await store.send(.router(.routeAction(
      id: 2,
      action: .battleFlow(.delegate(.openReport(classID: room.id)))
    )))
    #expect(store.state.routes.count == 4)
    guard case .battleFlow = store.state.routes[2].screen else {
      Issue.record("리포트 뒤로가기를 위한 의견 화면 경로가 사라졌습니다")
      return
    }
    guard case let .ownerDashboard(dashboard)? = store.state.routes.last?.screen else {
      Issue.record("TTS 의견 화면에서 리포트로 이동하지 않았습니다")
      return
    }
    #expect(dashboard.room.id == room.id)
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
    state.routes.push(.detail(testDetailState(room: room)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classMockRepository = MockClassRepository(rooms: [room])
      $0.uuid = .incrementing
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

  @Test
  func AI_최종투표_후_이전_투표와_채팅을_정리하고_의견으로_이동한다() async {
    let room = ClassRoom.mocks[0]
    var state = ClassCoordinator.State()
    state.routes.push(.detail(testDetailState(room: room)))
    state.routes.push(.aiVote(.init(
      room: room,
      battleID: room.battle.id,
      instanceID: UUID(),
      isPostVote: false
    )))
    state.routes.push(.aiChat(.init(room: room, battleID: room.battle.id, selectedOptionID: 1)))
    state.routes.push(.aiVote(.init(
      room: room,
      battleID: room.battle.id,
      instanceID: UUID(),
      isPostVote: true
    )))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 4,
      action: .aiVote(.delegate(.voteSubmitted(
        battleID: room.battle.id,
        selectedOptionID: 1,
        hasCompletedPostVote: true
      )))
    )))

    #expect(store.state.routes.count == 3)
    guard case let .battleFlow(flow)? = store.state.routes.last?.screen else {
      Issue.record("AI 최종 투표 후 의견 화면이 열리지 않았습니다")
      return
    }
    #expect(flow.opensResultsDirectly)
    #expect(flow.room?.id == room.id)
  }

  @Test
  func 상세_경로가_없어도_AI_완료_경로를_모두_정리한다() async {
    let room = ClassRoom.mocks[0]
    var state = ClassCoordinator.State()
    state.routes.push(.aiVote(.init(
      room: room,
      battleID: room.battle.id,
      instanceID: UUID(),
      isPostVote: false
    )))
    state.routes.push(.aiChat(.init(room: room, battleID: room.battle.id, selectedOptionID: 1)))
    state.routes.push(.aiVote(.init(
      room: room,
      battleID: room.battle.id,
      instanceID: UUID(),
      isPostVote: true
    )))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 3,
      action: .aiVote(.delegate(.voteSubmitted(
        battleID: room.battle.id,
        selectedOptionID: 1,
        hasCompletedPostVote: true
      )))
    )))

    #expect(store.state.routes.count == 2)
    guard case .battleFlow? = store.state.routes.last?.screen else {
      Issue.record("AI 완료 후 이전 단계가 남았습니다")
      return
    }
  }
}
