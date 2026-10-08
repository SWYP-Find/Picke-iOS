import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
@testable import Picke
import TCAFlow
import Testing

@MainActor
struct ClassCoordinatorTests {
  @Test
  func 클래스_배틀은_기존_채팅_경로로_진입한다() async {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let session = ClassMockChatSession()
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    } withDependencies: {
      $0.classMockRepository = repository
      $0.classMockChatSession = session
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openBattle(room)))
    )))
    let battleID = -1_000_000 - room.id
    await store.receive(\.inner, .mockBattleRegistered(roomID: room.id, battleID: battleID))

    guard case let .chat(chat)? = store.state.routes.last?.screen,
          case let .preVote(vote)? = chat.routes.last?.screen
    else {
      Issue.record("클래스 목 배틀이 기존 채팅 경로로 열리지 않음")
      return
    }
    #expect(vote.battleId == battleID)
  }

  @Test
  func AI_질문_클래스는_목_단일_투표_화면으로_진입한다() async throws {
    let original = ClassRoom.mocks[0]
    let setting = ClassSettingFeature.State(
      aiQuestion: ClassAIQuestion.examples[0],
      filter: .init(),
      deadline: original.deadline
    )
    let battle = try #require(setting.aiBattle)
    let room = ClassRoom(
      id: original.id,
      name: original.name,
      joinCode: original.joinCode,
      battle: battle,
      deadline: original.deadline,
      memberCount: original.memberCount,
      role: original.role,
      status: original.status,
      allowsAnonymousOpinion: original.allowsAnonymousOpinion,
      requiresComment: original.requiresComment
    )
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let session = ClassMockChatSession()
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    } withDependencies: {
      $0.classMockRepository = repository
      $0.classMockChatSession = session
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openBattle(room)))
    )))
    let battleID = -1_000_000 - room.id
    await store.receive(\.inner, .mockBattleRegistered(roomID: room.id, battleID: battleID))

    guard case let .aiVote(vote)? = store.state.routes.last?.screen else {
      Issue.record("AI 질문 클래스가 단일 투표 화면으로 열리지 않음")
      return
    }
    #expect(vote.battleID == battleID)
    #expect(vote.room == room)

    await store.send(.router(.routeAction(
      id: 2,
      action: .aiVote(.delegate(.voteSubmitted(battleID: battleID)))
    )))
    guard case let .chat(chat)? = store.state.routes.last?.screen,
          case let .comment(comment)? = chat.routes.last?.screen
    else {
      Issue.record("AI 단일 투표 후 댓글 화면으로 이어지지 않음")
      return
    }
    #expect(comment.battleId == battleID)

    let routeCount = store.state.routes.count
    await store.send(.router(.routeAction(
      id: 2,
      action: .aiVote(.delegate(.voteSubmitted(battleID: battleID)))
    )))
    #expect(store.state.routes.count == routeCount)

    let previousStats = try await session.fetchVoteStats(battleId: battleID)
    _ = try await session.submitPreVote(battleId: battleID, optionId: 1)
    let votedStats = try await session.fetchVoteStats(battleId: battleID)
    #expect(votedStats.totalCount == previousStats.totalCount + 1)
    #expect(votedStats.options[0].voteCount == previousStats.options[0].voteCount + 1)

    _ = try await session.createPerspective(battleId: battleID, content: "반대 의견", optionId: 2)
    let battleAfterOpinion = try await session.fetchBattle(battleId: battleID)
    let statsAfterOpinion = try await session.fetchVoteStats(battleId: battleID)
    #expect(battleAfterOpinion.userVoteStatus == .pro)
    #expect(statsAfterOpinion.options[0].voteCount == votedStats.options[0].voteCount)
    #expect(statsAfterOpinion.options[1].voteCount == votedStats.options[1].voteCount)
  }

  @Test
  func 클래스_채팅은_클래스_목_DI에서_배틀을_읽는다() async {
    let room = ClassRoom.mocks[0]
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let store = TestStore(initialState: ClassCoordinator.ClassScreen.State.chat(
      .init(route: .preVote(battleId: battleID))
    )) {
      ClassCoordinator.ClassScreen.body
    } withDependencies: {
      $0.classMockChatSession = session
      $0.battleUseCase = MockBattleRepository()
    }
    store.exhaustivity = .off

    await store.send(.chat(.router(.routeAction(
      id: 0,
      action: .preVote(.async(.fetchBattleDetail))
    ))))
    await store.finish()

    guard case let .chat(chat) = store.state,
          case let .preVote(vote)? = chat.routes.last?.screen,
          let detail = vote.battleDetail
    else {
      Issue.record("클래스 목 배틀 상세를 불러오지 못함")
      return
    }
    #expect(detail.battleInfo.battleId == battleID)
    #expect(detail.battleInfo.title == room.battle.title)
  }

  @Test
  func AI_단일_투표는_클래스_목_DI에_결과를_저장한다() async throws {
    let room = ClassRoom.mocks[0]
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let store = TestStore(initialState: ClassCoordinator.ClassScreen.State.aiVote(
      .init(room: room, battleID: battleID)
    )) {
      ClassCoordinator.ClassScreen.body
    } withDependencies: {
      $0.classMockChatSession = session
    }
    store.exhaustivity = .off

    await store.send(.aiVote(.view(.optionTapped(1))))
    await store.send(.aiVote(.view(.submitTapped)))
    await store.finish()

    let battle = try await session.fetchBattle(battleId: battleID)
    #expect(battle.userVoteStatus == .pro)
  }

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
  func 운영자_요약의_관리_메뉴에서_상세_수정으로_돌아간다() async {
    let room = ClassRoom.mocks[0]
    var dashboard = ClassOwnerDashboardFeature.State.preview(room: room)
    dashboard.management = .init(kind: .management)
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(dashboard))
    #expect(!state.showsTabBar)

    let store = TestStore(initialState: state) {
      ClassCoordinator()
    }
    store.exhaustivity = .off
    await store.send(.router(.routeAction(
      id: 2,
      action: .ownerDashboard(.delegate(.editClass))
    )))
    await store.finish()

    guard case let .detail(detail)? = store.state.routes.last?.screen else {
      Issue.record("클래스 상세로 돌아가지 않음")
      return
    }
    #expect(detail.modal?.kind == .deadline)
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
