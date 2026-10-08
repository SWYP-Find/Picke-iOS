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
    let battleAPI: any BattleInterface = session
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
      action: .aiVote(.view(.optionTapped(1)))
    )))
    await store.send(.router(.routeAction(
      id: 2,
      action: .aiVote(.delegate(.voteSubmitted(
        battleID: battleID,
        selectedOptionID: 1,
        hasCompletedPostVote: false
      )))
    )))
    guard case let .aiChat(aiChat)? = store.state.routes.last?.screen else {
      Issue.record("AI 질문 사전 투표 후 AI 채팅 화면으로 이어지지 않음")
      return
    }
    #expect(aiChat.battleID == battleID)
    #expect(aiChat.room == room)
    #expect(aiChat.selectedOptionID == 1)

    let routeCount = store.state.routes.count
    await store.send(.router(.routeAction(
      id: 2,
      action: .aiVote(.delegate(.voteSubmitted(
        battleID: battleID,
        selectedOptionID: 1,
        hasCompletedPostVote: false
      )))
    )))
    #expect(store.state.routes.count == routeCount)

    await store.send(.router(.routeAction(
      id: 3,
      action: .aiChat(.delegate(.finalVote(battleID: battleID)))
    )))
    guard case let .chat(finalVoteChat)? = store.state.routes.last?.screen,
          case let .preVote(finalVote)? = finalVoteChat.routes.last?.screen
    else {
      Issue.record("AI 채팅 완료 후 기존 최종투표 화면으로 이어지지 않음")
      return
    }
    #expect(finalVote.battleId == battleID)
    #expect(finalVote.voteMode == .post)

    let previousStats = try await battleAPI.fetchVoteStats(battleId: battleID)
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    let votedStats = try await battleAPI.fetchVoteStats(battleId: battleID)
    #expect(votedStats.totalCount == previousStats.totalCount + 1)
    #expect(votedStats.options[0].voteCount == previousStats.options[0].voteCount + 1)

    let opinion = try await battleAPI.createPerspective(
      battleId: battleID,
      content: "다른 탭에서 쓴 의견",
      optionId: 2
    )
    let battleAfterOpinion = try await battleAPI.fetchBattle(battleId: battleID)
    let statsAfterOpinion = try await battleAPI.fetchVoteStats(battleId: battleID)
    #expect(opinion?.option.optionId == 1)
    #expect(battleAfterOpinion.userVoteStatus == .pro)
    #expect(statsAfterOpinion.options[0].voteCount == votedStats.options[0].voteCount)
    #expect(statsAfterOpinion.options[1].voteCount == votedStats.options[1].voteCount)
  }

  @Test
  func 사후_투표를_마친_AI_질문_클래스는_댓글로_재진입한다() async throws {
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
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: room)
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 2)
    var vote = ClassAIVoteFeature.State(room: room, battleID: battleID)
    vote.selectedOptionID = 2
    vote.hasSubmitted = true
    vote.hasCompletedPostVote = true
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.aiVote(vote))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classMockChatSession = session
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 2,
      action: .aiVote(.delegate(.voteSubmitted(
        battleID: battleID,
        selectedOptionID: 2,
        hasCompletedPostVote: true
      )))
    )))
    await store.receive(\.inner, .completedAIVoteResolved(battleID: battleID, isMindChanged: true))
    guard case let .chat(chat)? = store.state.routes.last?.screen,
          case let .comment(comment)? = chat.routes.last?.screen
    else {
      Issue.record("완료된 AI 질문 배틀이 댓글 화면으로 열리지 않음")
      return
    }
    #expect(comment.battleId == battleID)
    #expect(comment.isMindChanged)
  }

  @Test
  func AI_채팅의_사후_투표_댓글에서_뒤로_가면_채팅으로_돌아오고_재투표하지_않는다() async {
    let room = ClassRoom.mocks[0]
    let battleID = -1_000_000 - room.id
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.aiChat(.init(room: room, battleID: battleID, selectedOptionID: 1)))
    state.routes.push(.chat(.init(route: .finalVote(battleId: battleID))))
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 3,
      action: .chat(.router(.routeAction(
        id: 0,
        action: .preVote(.delegate(.voteSubmitted(
          battleId: battleID,
          voteMode: .post,
          result: .init(voteId: 1, status: .created),
          isMindChanged: true
        )))
      )))
    )))
    #expect(store.state.completedAIBattles[battleID] == true)

    await store.send(.router(.routeAction(
      id: 3,
      action: .chat(.router(.routeAction(id: 1, action: .comment(.delegate(.dismiss)))))
    )))
    guard case .aiChat? = store.state.routes.last?.screen else {
      Issue.record("댓글 뒤로 가기가 AI 채팅으로 돌아오지 않음")
      return
    }

    await store.send(.router(.routeAction(
      id: 2,
      action: .aiChat(.delegate(.finalVote(battleID: battleID)))
    )))
    guard case let .chat(reopenedChat)? = store.state.routes.last?.screen,
          case let .comment(comment)? = reopenedChat.routes.last?.screen
    else {
      Issue.record("완료된 사후 투표를 다시 열어 댓글로 이동하지 않음")
      return
    }
    #expect(comment.battleId == battleID)
    #expect(comment.isMindChanged)
  }

  @Test
  func 클래스_채팅은_클래스_목_DI에서_배틀을_읽는다() async {
    let room = ClassRoom.mocks[0]
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    state.classState.routes.push(.chat(.init(route: .preVote(battleId: battleID))))
    let store = TestStore(initialState: state) {
      MainTabCoordinator()
    } withDependencies: {
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
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: room)
    let store = TestStore(initialState: ClassCoordinator.ClassScreen.State.aiVote(
      .init(room: room, battleID: battleID)
    )) {
      ClassCoordinator.ClassScreen.body
    } withDependencies: {
      $0.classMockChatSession = session
      $0.battleUseCase = session
    }
    store.exhaustivity = .off

    await store.send(.aiVote(.view(.optionTapped(1))))
    await store.send(.aiVote(.view(.submitTapped)))
    await store.finish()

    let battle = try await battleAPI.fetchBattle(battleId: battleID)
    #expect(battle.userVoteStatus == .pro)
  }

  @Test
  func 사전_A에서_사후_B로_바꾸면_B_통계를_유지하고_중복_사후_투표를_거절한다() async throws {
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: ClassRoom.mocks[0])
    let initial = try await battleAPI.fetchVoteStats(battleId: battleID)

    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    let afterPreVote = try await battleAPI.fetchVoteStats(battleId: battleID)
    #expect(afterPreVote.options[0].voteCount == initial.options[0].voteCount + 1)
    #expect(afterPreVote.options[1].voteCount == initial.options[1].voteCount)

    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 2)
    let afterPostVote = try await battleAPI.fetchVoteStats(battleId: battleID)
    #expect(afterPostVote.options[0].voteCount == initial.options[0].voteCount)
    #expect(afterPostVote.options[1].voteCount == initial.options[1].voteCount + 1)
    #expect(afterPostVote.totalCount == initial.totalCount + 1)
    #expect(await session.hasChangedMind(battleID: battleID))

    var duplicateWasRejected = false
    do {
      _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 1)
    } catch {
      duplicateWasRejected = true
    }
    #expect(duplicateWasRejected)

    let afterRejectedVote = try await battleAPI.fetchVoteStats(battleId: battleID)
    let battle = try await battleAPI.fetchBattle(battleId: battleID)
    #expect(afterRejectedVote.options == afterPostVote.options)
    #expect(afterRejectedVote.totalCount == afterPostVote.totalCount)
    #expect(battle.userVoteStatus == .con)
    #expect(await session.hasChangedMind(battleID: battleID))
  }

  @Test
  func AI_B_투표_후_남긴_댓글은_B_진영으로_표시된다() async throws {
    let room = ClassRoom.mocks[0]
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let perspectiveAPI: any PerspectiveInterface = session
    let battleID = await session.register(room: room)
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 2)
    let created = try await battleAPI.createPerspective(
      battleId: battleID,
      content: "B를 선택한 의견",
      optionId: 1
    )
    let perspective = try #require(created)
    #expect(perspective.option.optionId == 2)
    _ = try await perspectiveAPI.createComment(perspectiveId: perspective.perspectiveId, content: "동의해요")

    let comments = try await perspectiveAPI.fetchLabeledComments(
      perspectiveId: perspective.perspectiveId,
      cursor: nil,
      size: nil
    )
    #expect(comments.items.first?.stance == room.battle.optionBTitle)
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
    await store.receive {
      guard case .router(.routeAction(id: 1, action: .detail(.view(.deadlineTapped)))) = $0 else { return false }
      return true
    }
    await store.finish()

    guard case let .detail(detail)? = store.state.routes.last?.screen else {
      Issue.record("클래스 상세로 돌아가지 않음")
      return
    }
    #expect(detail.modal?.kind == .deadline)
  }

  @Test
  func 운영자_마감일_수정_후_다시_연_보고서는_목_미리보기를_유지한다() async throws {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let updatedRoom = try await repository.updateDeadline(
      id: room.id,
      deadline: room.deadline.addingTimeInterval(86400)
    )
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(.preview(room: room)))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 2,
      action: .ownerDashboard(.delegate(.editClass))
    )))
    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.inner(.deadlineUpdated(.success(updatedRoom))))
    )))
    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openReport(updatedRoom)))
    )))
    await store.finish()

    guard case let .ownerDashboard(dashboard)? = store.state.routes.last?.screen else {
      Issue.record("마감일 변경 후 운영자 보고서가 열리지 않음")
      return
    }
    #expect(dashboard.room.deadline == updatedRoom.deadline)
    #expect(dashboard.usesPreviewContent)
  }

  @Test
  func 마감_배틀에서_연_운영자_요약의_삭제는_상세_확인창으로_돌아간다() async {
    let room = ClassRoom.mocks[2]
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.closedBattle(.init(room: room)))
    state.routes.push(.ownerDashboard(.init(room: room)))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 3,
      action: .ownerDashboard(.delegate(.deleteClass))
    )))
    await store.receive {
      guard case .router(.routeAction(id: 1, action: .detail(.view(.deleteTapped)))) = $0 else { return false }
      return true
    }
    await store.finish()

    #expect(store.state.routes.count == 2)
    guard case let .detail(detail)? = store.state.routes.last?.screen else {
      Issue.record("운영자 삭제 확인 화면이 클래스 상세로 돌아가지 않음")
      return
    }
    #expect(detail.customAlert != nil)
  }

  @Test
  func 멤버_화면은_시트_상태에_관계없이_탭바를_숨긴다() {
    var state = ClassCoordinator.State()
    #expect(!state.showsTabBar)
    state.routes.push(.detail(.init(room: .mocks[0])))
    var members = ClassMemberFeature.State(room: .mocks[0])
    state.routes.push(.members(members))
    #expect(!state.showsTabBar)

    members.filter = .init()
    state.routes[screenAt: 2] = .members(members)
    #expect(!state.showsTabBar)

    members.filter = nil
    members.editName = .init()
    state.routes[screenAt: 2] = .members(members)
    #expect(!state.showsTabBar)

    members.editName = nil
    state.routes[screenAt: 2] = .members(members)
    #expect(!state.showsTabBar)

    members.customAlert = .alert(title: "확인", message: "안내")
    state.routes[screenAt: 2] = .members(members)
    #expect(!state.showsTabBar)

    state.routes.goBack()
    #expect(state.showsTabBar)
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
    #expect(!store.state.showsTabBar)

    await store.send(.router(.routeAction(id: 3, action: .report(.delegate(.dismiss)))))
    await store.receive {
      guard case .view(.backAction) = $0 else { return false }
      return true
    }
    await store.send(.router(.routeAction(id: 2, action: .closedBattle(.delegate(.dismiss)))))
    await store.receive {
      guard case .view(.backAction) = $0 else { return false }
      return true
    }
    #expect(store.state.showsTabBar)
  }

  @Test
  func 운영자_대시보드는_관리_시트와_관계없이_탭바를_숨기고_상세로_돌아오면_보인다() async {
    let room = ClassRoom.mocks[0]
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openReport(room)))
    )))
    #expect(!store.state.showsTabBar)
    guard case .ownerDashboard? = store.state.routes.last?.screen else {
      Issue.record("운영자 대시보드가 열리지 않음")
      return
    }

    await store.send(.router(.routeAction(
      id: 2,
      action: .ownerDashboard(.delegate(.dismiss))
    )))
    await store.receive {
      guard case .view(.backAction) = $0 else { return false }
      return true
    }
    #expect(store.state.showsTabBar)
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
    await store.skipReceivedActions()

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
