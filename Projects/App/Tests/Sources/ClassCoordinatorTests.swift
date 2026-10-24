//
//  ClassCoordinatorTests.swift
//  PickeTests
//
//  Created by Picke on 10/11/26.
//

import AudioPlayerServiceInterface
import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import Foundation
@testable import Picke
import TCAFlow
import Testing

@MainActor
struct ClassCoordinatorTests {
  @Test
  func 추천_배틀_미리듣기는_push로_열고_뒤로가면_추천_목록으로_돌아온다() async {
    let battle = ClassBattleSummary.mocks[0]
    var state = ClassCoordinator.State()
    state.routes.push(.recommend(.init(filter: .init())))
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .recommend(.delegate(.previewRequested(battle)))
    )))
    #expect(store.state.routes.count == 3)
    guard case let .battlePreview(preview)? = store.state.routes.last?.screen else {
      Issue.record("미리듣기 화면이 push되지 않았습니다.")
      return
    }
    #expect(preview.battle.id == battle.id)

    await store.send(.router(.routeAction(
      id: 2,
      action: .battlePreview(.delegate(.dismiss))
    )))
    await store.receive(\.view.backAction)
    #expect(store.state.routes.count == 2)
    guard case .recommend? = store.state.routes.last?.screen else {
      Issue.record("뒤로 가기 후 추천 목록이 복원되지 않았습니다.")
      return
    }
  }

  @Test
  func AI_투표_등장_이벤트는_현재_화면_인스턴스에만_전달한다() {
    let room = ClassRoom.mockClosedSociety
    let instanceID = UUID()
    let vote = ClassAIVoteFeature.State(
      room: room,
      battleID: -1_000_000 - room.id,
      instanceID: instanceID
    )
    var state = ClassCoordinator.State()
    state.routes.push(.aiVote(vote))
    #expect(ClassCoordinatorView.isActiveAIVote(instanceID, in: state.routes))

    state.routes.goBack()
    #expect(!ClassCoordinatorView.isActiveAIVote(instanceID, in: state.routes))

    withDependencies {
      $0.uuid = .incrementing
    } operation: {
      state.routes.push(.report(.init(room: room)))
    }
    #expect(!ClassCoordinatorView.isActiveAIVote(instanceID, in: state.routes))

    state.routes[screenAt: 1] = .aiVote(.init(
      room: room,
      battleID: vote.battleID,
      instanceID: UUID()
    ))
    #expect(!ClassCoordinatorView.isActiveAIVote(instanceID, in: state.routes))
  }

  @Test
  func 클래스_목_오디오_속도_변경은_재생시간을_이어가고_로드해도_속도를_유지한다() async {
    let now = LockIsolated(Date(timeIntervalSince1970: 1_760_000_000))
    let player = ClassMockAudioPlayer(now: { now.value })
    let url = URL(string: "picke-class-mock://audio")!

    #expect(await player.load(url: url))
    await player.play()
    now.withValue { $0 = $0.addingTimeInterval(1) }
    #expect(await player.currentTime() == 1)

    await player.setPlaybackRate(2)
    #expect(await player.currentTime() == 1)
    now.withValue { $0 = $0.addingTimeInterval(1) }
    #expect(await player.currentTime() == 3)

    await player.pause()
    now.withValue { $0 = $0.addingTimeInterval(1) }
    #expect(await player.currentTime() == 3)
    await player.play()
    now.withValue { $0 = $0.addingTimeInterval(1) }
    #expect(await player.currentTime() == 5)

    #expect(await player.load(url: url))
    await player.play()
    now.withValue { $0 = $0.addingTimeInterval(1) }
    #expect(await player.currentTime() == 2)
  }

  @Test
  func 클래스_표시정보는_배틀별로_보관하고_이전_화면의_등록응답은_무시한다() async {
    let first = ClassRoom.mocks[0]
    let second = ClassRoom.mockJoinable
    let firstBattleID = -1_000_000 - first.id
    let secondBattleID = -1_000_000 - second.id
    var state = ClassCoordinator.State()
    state.chatRoomsByBattleID[firstBattleID] = first
    state.routes.push(.detail(.init(room: second)))
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.inner(.mockBattleRegistered(roomID: first.id, battleID: firstBattleID)))
    #expect(store.state.routes.count == 2)
    #expect(store.state.chatRoomsByBattleID == [firstBattleID: first])

    await store.send(.inner(.mockBattleRegistered(roomID: second.id, battleID: secondBattleID)))
    #expect(store.state.chatRoomsByBattleID[firstBattleID] == first)
    #expect(store.state.chatRoomsByBattleID[secondBattleID] == second)

    await store.send(.view(.backToRootAction))
    #expect(store.state.chatRoomsByBattleID.isEmpty)
    #expect(store.state.routes.count == 1)
  }

  @Test
  func 스와이프로_루트에_돌아오면_클래스_표시정보도_초기화한다() async {
    let room = ClassRoom.mockJoinable
    var state = ClassCoordinator.State()
    state.chatRoomsByBattleID[-1_000_000 - room.id] = room
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.router(.updateRoutes([state.routes[0]])))
    #expect(store.state.chatRoomsByBattleID.isEmpty)
  }

  @Test
  func 목록을_닫아_탈퇴_정리를_놓쳐도_재참여_전에는_개인_배틀을_초기화한다() async throws {
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let battleAPI: any BattleInterface = session
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 2)
    _ = try await battleAPI.createPerspective(battleId: battleID, content: "이전 참여 의견", optionId: 2)
    var state = ClassCoordinator.State()
    state.completedAIBattles[battleID] = true
    let codeID = UUID()
    let nicknameID = UUID()
    state.routes.push(.join(.init(mode: .code, instanceID: codeID)))
    state.routes.push(.join(.init(mode: .nickname, instanceID: nicknameID)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classMockChatSession = session
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .join(.delegate(.joined(
      room,
      nickname: "새 이름",
      instanceID: nicknameID
    ))))))
    let requestID = try #require(store.state.pendingJoinID)
    await store.receive(\.inner, .joinedSessionCleared(requestID, room))
    await store.finish()
    #expect(store.state.completedAIBattles[battleID] == nil)
    guard case let .detail(detail)? = store.state.routes.last?.screen else {
      Issue.record("새 참여 기록이 정리된 뒤 클래스 상세로 진입해야 합니다.")
      return
    }
    #expect(detail.room == room)
    _ = await session.register(room: room)
    #expect(await session.hasChangedMind(battleID: battleID) == false)
    #expect(try await battleAPI.fetchMyPerspective(battleId: battleID) == nil)
  }

  @Test
  func 클래스에서_나가면_개인_배틀_기록을_지운_뒤_목록을_갱신한다() async throws {
    let room = ClassRoom.mockJoinable
    let session = ClassMockChatSession()
    let battleID = await session.register(room: room)
    let battleAPI: any BattleInterface = session
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 2)
    #expect(await session.hasChangedMind(battleID: battleID))
    let listeningKey = "picke.chatRoom.hasFinishedListening.\(battleID)"
    UserDefaults.standard.set(true, forKey: listeningKey)
    defer { UserDefaults.standard.removeObject(forKey: listeningKey) }

    var list = MyClassFeature.State()
    list.rooms = [room]
    list.viewState = .loaded
    list.selectedRoomID = room.id
    list.isLeaving = true
    list.leavingRoomID = room.id
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(list))
    state.completedAIBattles[battleID] = true
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    } withDependencies: {
      $0.classMockChatSession = session
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 1, action: .myClasses(.delegate(.left(room.id))))))
    await store.receive(\.inner, .membershipSessionCleared(routeID: 1, roomID: room.id))
    await store.receive {
      guard case let .router(.routeAction(id, action: .myClasses(.inner(.leaveCleanupCompleted(roomID))))) = $0
      else { return false }
      return id == 1 && roomID == room.id
    }
    await store.finish()

    #expect(await session.hasChangedMind(battleID: battleID) == false)
    #expect(UserDefaults.standard.object(forKey: listeningKey) == nil)
    #expect(store.state.completedAIBattles[battleID] == nil)
    guard case let .myClasses(updated)? = store.state.routes.last?.screen else {
      Issue.record("클래스 나가기 후 목록 경로가 유지되어야 합니다.")
      return
    }
    #expect(updated.rooms.isEmpty)
    #expect(updated.isLeaving == false)
    _ = await session.register(room: room)
    #expect(await session.hasChangedMind(battleID: battleID) == false)
  }

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
    #expect(vote.showsResultsForExistingParticipation)
  }

  @Test
  func 클래스_기참여자는_사전투표_화면에_남아_선택없이_결과를_보고_재투표하지_않는다() async throws {
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: ClassRoom.mocks[0])
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    let perspective = try #require(try await battleAPI.createPerspective(
      battleId: battleID,
      content: "기참여 의견",
      optionId: 1
    ))
    let beforeStats = try await battleAPI.fetchVoteStats(battleId: battleID)
    var state = PreVoteFeature.State(battleId: battleID)
    state.showsResultsForExistingParticipation = true
    state.selectedOptionId = 2
    let store = TestStore(initialState: state) { PreVoteFeature() } withDependencies: {
      $0.battleUseCase = session
    }

    await store.send(.inner(.myPerspectiveResponse(.success(perspective)))) {
      $0.myPerspective = perspective
      $0.selectedOptionId = nil
    }
    #expect(store.state.selectedOptionId == nil)
    #expect(store.state.isShowingParticipationResult)
    #expect(store.state.primaryButtonTitle == "결과 보기")
    #expect(store.state.isPrimaryButtonEnabled)
    await store.send(.view(.optionTapped(optionId: 2)))
    #expect(store.state.selectedOptionId == nil)
    await store.send(.view(.primaryButtonTapped))
    await store.receive(\.delegate, .alreadyFinalVoted(battleId: battleID))
    let afterStats = try await battleAPI.fetchVoteStats(battleId: battleID)
    #expect(afterStats.options == beforeStats.options)
    #expect(afterStats.totalCount == beforeStats.totalCount)
    #expect(try await battleAPI.fetchBattle(battleId: battleID).userVoteStatus == .pro)
  }

  @Test
  func 완료_상세는_의견이_없어도_결과_버튼을_표시한다() async throws {
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: ClassRoom.mocks[0])
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 1)
    let fetched = try await battleAPI.fetchBattle(battleId: battleID)
    for step in [BattleStep.completed, .finished] {
      let detail = BattleDetail(
        battleInfo: fetched.battleInfo,
        description: fetched.description,
        shareUrl: fetched.shareUrl,
        userVoteStatus: fetched.userVoteStatus,
        currentStep: step,
        categoryTags: fetched.categoryTags,
        philosopherTags: fetched.philosopherTags,
        valueTags: fetched.valueTags
      )
      for detailFirst in [false, true] {
        var state = PreVoteFeature.State(battleId: battleID)
        state.showsResultsForExistingParticipation = true
        let store = TestStore(initialState: state) { PreVoteFeature() }
        store.exhaustivity = .off

        if detailFirst {
          await store.send(.inner(.battleDetailResponse(.success(detail))))
          #expect(store.state.isShowingParticipationResult)
          await store.send(.inner(.myPerspectiveResponse(.success(nil))))
        } else {
          await store.send(.inner(.myPerspectiveResponse(.success(nil))))
          #expect(!store.state.isShowingParticipationResult)
          await store.send(.inner(.battleDetailResponse(.success(detail))))
        }
        #expect(store.state.isShowingParticipationResult)
        #expect(store.state.isPrimaryButtonEnabled)
        await store.send(.view(.optionTapped(optionId: 1)))
        #expect(store.state.selectedOptionId == nil)
        await store.send(.view(.primaryButtonTapped))
        await store.receive(\.delegate, .alreadyFinalVoted(battleId: battleID))
        #expect(try await battleAPI.fetchBattle(battleId: battleID).userVoteStatus == .pro)
      }
    }
  }

  @Test
  func 클래스_미참여_사전과_청취_단계는_결과_버튼으로_전환하지_않는다() async throws {
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: ClassRoom.mocks[0])
    let preVoteDetail = try await battleAPI.fetchBattle(battleId: battleID)
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    let listeningDetail = try await battleAPI.fetchBattle(battleId: battleID)
    #expect(preVoteDetail.currentStep == .preVote)
    #expect(listeningDetail.currentStep == .listening)

    for detail in [preVoteDetail, listeningDetail] {
      var state = PreVoteFeature.State(battleId: battleID)
      state.showsResultsForExistingParticipation = true
      let store = TestStore(initialState: state) { PreVoteFeature() }
      store.exhaustivity = .off
      await store.send(.inner(.battleDetailResponse(.success(detail))))
      await store.send(.inner(.myPerspectiveResponse(.success(nil))))
      #expect(!store.state.isShowingParticipationResult)
      #expect(store.state.primaryButtonTitle == "사전 투표하기")
      #expect(!store.state.isPrimaryButtonEnabled)
      await store.send(.view(.optionTapped(optionId: 2)))
      #expect(store.state.selectedOptionId == 2)
      #expect(store.state.isPrimaryButtonEnabled)
    }
  }

  @Test
  func 관점이_먼저_도착하고_상세가_실패해도_재시도로_결과_화면을_복구한다() async throws {
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: ClassRoom.mocks[0])
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    let perspective = try #require(try await battleAPI.createPerspective(
      battleId: battleID,
      content: "재시도 의견",
      optionId: 1
    ))
    let detail = try await battleAPI.fetchBattle(battleId: battleID)
    var state = PreVoteFeature.State(battleId: battleID)
    state.showsResultsForExistingParticipation = true
    let store = TestStore(initialState: state) { PreVoteFeature() } withDependencies: {
      $0.battleUseCase = session
    }
    store.exhaustivity = .off

    await store.send(.inner(.myPerspectiveResponse(.success(perspective))))
    await store.send(.inner(.battleDetailResponse(.failure(.noData))))
    #expect(store.state.detailLoadFailed)
    #expect(store.state.battle == nil)
    await store.send(.view(.retryTapped))
    await store.receive(\.async, .fetchBattleDetail)
    await store.receive(\.inner, .battleDetailResponse(.success(detail)))
    #expect(!store.state.detailLoadFailed)
    #expect(store.state.battle != nil)
    #expect(store.state.isShowingParticipationResult)
  }

  @Test
  func 일반_사전투표는_기참여시_기존처럼_자동직행하고_사후투표는_기존_선택을_요구한다() async throws {
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: ClassRoom.mocks[0])
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    let perspective = try #require(try await battleAPI.createPerspective(
      battleId: battleID,
      content: "의견",
      optionId: 1
    ))
    let preStore = TestStore(initialState: PreVoteFeature.State(battleId: battleID)) { PreVoteFeature() }
    preStore.exhaustivity = .off
    await preStore.send(.inner(.myPerspectiveResponse(.success(perspective))))
    await preStore.receive(\.delegate, .alreadyFinalVoted(battleId: battleID))
    #expect(!preStore.state.isShowingParticipationResult)

    var postState = PreVoteFeature.State(battleId: battleID, voteMode: .post)
    postState.showsResultsForExistingParticipation = true
    postState.myPerspective = perspective
    let postStore = TestStore(initialState: postState) { PreVoteFeature() }
    postStore.exhaustivity = .off
    #expect(postStore.state.primaryButtonTitle == "최종 투표하기")
    #expect(!postStore.state.isPrimaryButtonEnabled)
    await postStore.send(.view(.optionTapped(optionId: 2)))
    #expect(postStore.state.selectedOptionId == 2)
    #expect(postStore.state.isPrimaryButtonEnabled)
  }

  @Test
  func 기참여_결과_버튼은_댓글_루트로_교체하고_뒤로가기는_클래스_상세로_돌아간다() async {
    let room = ClassRoom.mocks[0]
    let battleID = -1_000_000 - room.id
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    var chat = ChatCoordinator.State(route: .preVote(battleId: battleID))
    var vote = PreVoteFeature.State(battleId: battleID)
    vote.showsResultsForExistingParticipation = true
    chat.routes[screenAt: 0] = .preVote(vote)
    state.routes.push(.chat(chat))
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 2,
      action: .chat(.router(.routeAction(
        id: 0,
        action: .preVote(.delegate(.alreadyFinalVoted(battleId: battleID)))
      )))
    )))
    guard case let .chat(resultChat)? = store.state.routes.last?.screen,
          resultChat.routes.count == 1,
          case let .comment(comment)? = resultChat.routes.first?.screen
    else {
      Issue.record("기참여 결과 버튼이 댓글 루트로 교체되지 않음")
      return
    }
    #expect(comment.battleId == battleID)

    await store.send(.router(.routeAction(
      id: 2,
      action: .chat(.router(.routeAction(id: 0, action: .comment(.delegate(.dismiss)))))
    )))
    await store.receive {
      if case .router(.routeAction(id: 2, action: .chat(.delegate(.dismiss)))) = $0 {
        return true
      }
      return false
    }
    await store.receive {
      if case .view(.backAction) = $0 {
        return true
      }
      return false
    }
    guard case let .detail(detail)? = store.state.routes.last?.screen else {
      Issue.record("댓글 뒤로가기가 클래스 상세로 돌아가지 않음")
      return
    }
    #expect(detail.room.id == room.id)
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
      requiresComment: original.requiresComment,
      memberCapacity: original.memberCapacity
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
      $0.uuid = .incrementing
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
      requiresComment: original.requiresComment,
      memberCapacity: original.memberCapacity
    )
    let session = ClassMockChatSession()
    let battleAPI: any BattleInterface = session
    let battleID = await session.register(room: room)
    _ = try await battleAPI.submitPreVote(battleId: battleID, optionId: 1)
    _ = try await battleAPI.submitPostVote(battleId: battleID, optionId: 2)
    var vote = ClassAIVoteFeature.State(room: room, battleID: battleID, instanceID: UUID())
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
    let initialBattle = try await battleAPI.fetchBattle(battleId: battleID)
    let instanceID = UUID()
    let requestID = UUID()
    let store = TestStore(initialState: ClassCoordinator.ClassScreen.State.aiVote(
      .init(room: room, battleID: battleID, instanceID: instanceID)
    )) {
      ClassCoordinator.ClassScreen.body
    } withDependencies: {
      $0.classMockChatSession = session
      $0.battleUseCase = session
      $0.uuid = .constant(requestID)
    }
    store.exhaustivity = .off

    await store.send(.aiVote(.view(.onAppear)))
    await store.receive {
      guard case let .aiVote(.inner(.voteLoaded(
        receivedInstanceID,
        receivedRequestID,
        receivedBattleID,
        .success(progress)
      ))) = $0
      else { return false }
      return receivedInstanceID == instanceID && receivedRequestID == requestID
        && receivedBattleID == battleID && progress.status == initialBattle.userVoteStatus
        && progress.step == initialBattle.currentStep
    }
    await store.finish()
    guard case let .aiVote(vote) = store.state else {
      Issue.record("AI 투표 화면이 유지되어야 함")
      return
    }
    #expect(vote.viewState == .loaded)

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
  func 운영자_요약의_관리_메뉴에서_현재_화면_위로_마감일_편집을_연다() async {
    let room = ClassRoom.mocks[0]
    var dashboard = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    dashboard.management = .init(kind: .management)
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(dashboard))
    #expect(!state.showsTabBar)

    let store = TestStore(initialState: state) {
      ClassCoordinator()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = Date(timeIntervalSince1970: 1_760_000_000)
    }
    store.exhaustivity = .off
    await store.send(.router(.routeAction(
      id: 2,
      action: .ownerDashboard(.delegate(.editClass))
    )))
    await store.finish()

    guard case let .ownerDashboard(current)? = store.state.routes.last?.screen else {
      Issue.record("운영자 요약 화면이 유지되지 않았습니다.")
      return
    }
    #expect(current.instanceID == dashboard.instanceID)
    #expect(store.state.deadlineEdit?.room == room)
  }

  @Test
  func 운영자_마감일_수정_후_다시_연_보고서는_갱신된_방과_주입된_데이터를_표시한다() async throws {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let updatedRoom = try await repository.updateDeadline(
      id: room.id,
      deadline: room.deadline.addingTimeInterval(86400)
    )
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(.init(room: room, instanceID: UUID())))
    var editor = ClassDeadlineEditFeature.State(
      room: room,
      instanceID: UUID(),
      referenceNow: Date(timeIntervalSince1970: 1_760_000_000)
    )
    editor.isSaving = true
    editor.activeRequestID = UUID()
    state.deadlineEdit = editor
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    } withDependencies: {
      $0.classUseCase = repository
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off
    let requestID = try #require(editor.activeRequestID)

    await store.send(.deadlineEdit(.presented(.delegate(.saved(
      updatedRoom,
      instanceID: editor.instanceID,
      requestID: requestID
    )))))
    await store.send(.view(.backAction))
    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openReport(updatedRoom)))
    )))
    await store.send(.router(.routeAction(
      id: 2,
      action: .ownerDashboard(.view(.onAppear))
    )))
    await store.receive {
      guard case .router(.routeAction(id: 2, action: .ownerDashboard(.async(.fetchDashboard)))) = $0
      else { return false }
      return true
    }
    await store.receive {
      guard case let .router(.routeAction(id: 2, action: .ownerDashboard(action))) = $0,
            case .inner(.dashboardResponse) = action else { return false }
      return true
    }
    await store.finish()

    guard case let .ownerDashboard(dashboard)? = store.state.routes.last?.screen else {
      Issue.record("마감일 변경 후 운영자 보고서가 열리지 않음")
      return
    }
    #expect(dashboard.room.deadline == updatedRoom.deadline)
    #expect(dashboard.sourceViewState == .ready)
    #expect(dashboard.members == MockClassOwnerDashboard.figma.members)
    #expect(dashboard.opinions == MockClassOwnerDashboard.figma.opinions)
    #expect(dashboard.metrics == MockClassOwnerDashboard.figma.metrics)
  }

  @Test
  func 마감_배틀에서_연_운영자_요약의_삭제는_상세_확인창으로_돌아간다() async {
    let room = ClassRoom.mocks[2]
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.closedBattle(.init(room: room)))
    state.routes.push(.ownerDashboard(.init(room: room, instanceID: UUID())))
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
  func 운영자_멤버_목록은_필터와_저장중에만_탭바를_숨긴다() {
    var state = ClassCoordinator.State()
    #expect(!state.showsTabBar)
    state.routes.push(.detail(.init(room: .mocks[0])))
    var members = ClassMemberFeature.State(room: .mocks[0], instanceID: UUID())
    state.routes.push(.members(members))
    #expect(state.showsTabBar)

    members.filter = .init()
    state.routes[screenAt: 2] = .members(members)
    #expect(!state.showsTabBar)

    members.filter = nil
    state.routes[screenAt: 2] = .members(members)
    #expect(state.showsTabBar)

    members.editName = .init()
    state.routes[screenAt: 2] = .members(members)
    #expect(!state.showsTabBar)

    members.editName = nil
    state.routes[screenAt: 2] = .members(members)
    #expect(state.showsTabBar)

    members.customAlert = .alert(title: "확인", message: "안내")
    state.routes[screenAt: 2] = .members(members)
    #expect(!state.showsTabBar)

    members.customAlert = nil
    state.routes[screenAt: 2] = .members(members)
    #expect(state.showsTabBar)

    members.isSaving = true
    state.routes[screenAt: 2] = .members(members)
    #expect(!state.showsTabBar)

    members.isSaving = false
    state.routes[screenAt: 2] = .members(members)
    #expect(state.showsTabBar)

    state.routes.goBack()
    #expect(state.showsTabBar)
  }

  @Test
  func 참가자_멤버_목록도_확정_시안처럼_탭바를_보여준다() {
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: .mockJoinable)))
    #expect(state.showsTabBar)
    state.routes.push(.members(.init(room: .mockJoinable, instanceID: UUID())))
    #expect(state.showsTabBar)

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
  func 마감일_패널을_열면_탭바를_숨기고_닫으면_복구한다() async {
    let room = ClassRoom.mocks[0]
    var state = ClassCoordinator.State()
    var list = MyClassFeature.State()
    list.rooms = [room]
    list.viewState = .loaded
    state.routes.push(.myClasses(list))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
        .dependency(\.uuid, .incrementing)
        .dependency(\.date.now, Date(timeIntervalSince1970: 1_760_000_000))
    }
    store.exhaustivity = .off
    #expect(store.state.showsTabBar)
    await store.send(.router(.routeAction(id: 1, action: .myClasses(.delegate(.openInformation(room))))))
    await store.receive(\.inner, .deadlineDetailResponse(
      routeID: 1,
      roomID: room.id,
      .success(room)
    ))
    #expect(!store.state.showsTabBar)
    await store.send(.deadlineEdit(.presented(.view(.backTapped))))
    await store.receive(\.deadlineEdit.presented.delegate.dismiss)
    #expect(store.state.showsTabBar)
  }

  @Test
  func 마감_배틀_결과_화면에서는_탭바를_숨긴다() {
    var state = ClassCoordinator.State()
    state.routes.push(.closedBattle(.init(room: .mockClosedSociety)))
    #expect(!state.showsTabBar)
  }

  @Test
  func 내_의견은_push로_열고_뒤로가면_리포트_상태를_보존한다() async throws {
    var report = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID())
    report.report = MockClassReport.figmaMyOpinions
    report.sourceViewState = .ready
    report.selectedTab = .feedback
    report.feedback = ClassAIPersonalFeedback(
      summaryTitle: "보존할 피드백",
      summaryDetail: "상세",
      points: [],
      nextQuestion: "질문",
      nextHint: "힌트"
    )
    var opinions = ClassMyOpinionsFeature.State()
    opinions.opinions = MockClassReport.figmaMyOpinions.resolvedOpinions
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: .mockClosedSociety)))
    state.routes.push(.report(report))
    state.reportInstanceIDs = [report.instanceID]
    let originalRoutes = state.routes
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.routeAction(id: 2, action: .report(.view(.myOpinionsTapped)))))
    await store.receive(\.router.routeAction) {
      $0.routes.push(.myOpinions(opinions))
    }
    #expect(store.state.routes.last == .push(.myOpinions(opinions)))
    #expect(store.state.showsTabBar)
    #expect(store.state.routes[2].screen == .report(report))

    // Repeated navigation and an underlying report's late dismiss must not pop or push.
    await store.send(.router(.routeAction(id: 2, action: .report(.delegate(.openMyOpinions(report.instanceID))))))
    await store.send(.router(.routeAction(id: 2, action: .report(.delegate(.dismiss)))))
    await store.send(.router(.routeAction(id: 3, action: .myOpinions(.view(.backTapped)))))
    await store.receive(\.router.routeAction)
    await store.receive(\.view.backAction) {
      $0.routes.goBack()
    }
    #expect(store.state.routes == originalRoutes)
    #expect(store.state.showsTabBar)
    await store.finish()
  }

  @Test
  func 서버_개인_리포트에서_내_의견_화면을_열면_클래스_ID를_전달한다() async {
    let room = ClassRoom.mockClosedSociety
    var report = ClassReportFeature.State(room: room, instanceID: UUID())
    report.classResult = ClassResult(
      classID: room.id,
      closed: true,
      closeAt: room.deadline,
      stats: .init(
        activeMemberCount: 1,
        completedCount: 1,
        participationRate: 100,
        commentWriterCount: 1,
        commentRate: 100,
        postVoteCount: 1,
        options: []
      ),
      myReportState: "SUCCEEDED",
      insightState: nil
    )
    report.sourceViewState = .ready
    var state = ClassCoordinator.State()
    state.routes.push(.report(report))
    state.reportInstanceIDs = [report.instanceID]
    let store = TestStore(initialState: state) { ClassCoordinator() }
    await store.send(.router(.routeAction(id: 1, action: .report(.delegate(.openMyOpinions(report.instanceID)))))) {
      var opinions = ClassMyOpinionsFeature.State()
      opinions.classID = room.id
      $0.routes.push(.myOpinions(opinions))
    }
  }

  @Test
  func 내_의견은_다른_리포트_인스턴스나_로딩_중에는_열리지_않는다() async {
    var report = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID())
    report.report = MockClassReport.figma
    report.sourceViewState = .loading
    var state = ClassCoordinator.State()
    state.routes.push(.report(report))
    state.reportInstanceIDs = [report.instanceID]
    let store = TestStore(initialState: state) { ClassCoordinator() }
    await store.send(.router(.routeAction(id: 1, action: .report(.delegate(.openMyOpinions(report.instanceID))))))
    await store.finish()

    report.sourceViewState = .ready
    state.routes[screenAt: 1] = .report(report)
    let readyStore = TestStore(initialState: state) { ClassCoordinator() }
    await readyStore.send(.router(.routeAction(id: 1, action: .report(.delegate(.openMyOpinions(UUID()))))))
    await readyStore.finish()
  }

  @Test
  func 내_의견의_비활성_닫기는_무시하고_마감일_패널은_탭바를_숨긴다() async {
    var state = ClassCoordinator.State()
    state.routes.push(.myOpinions(.init()))
    state.routes.push(.myOpinions(.init()))
    let store = TestStore(initialState: state) { ClassCoordinator() }
    await store.send(.router(.routeAction(id: 1, action: .myOpinions(.delegate(.dismiss)))))
    #expect(store.state.showsTabBar)
    await store.finish()

    state.deadlineEdit = .init(
      room: .mockClosedSociety,
      instanceID: UUID(),
      referenceNow: Date(timeIntervalSince1970: 1_760_000_000)
    )
    #expect(!state.showsTabBar)
  }

  @Test
  func 운영자_내_의견은_push하고_돌아오면_리포트와_AI_상태를_보존한다() async {
    let room = ClassRoom.mocks[0]
    var dashboard = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    dashboard.report = MockClassReport.figmaMyOpinions
    dashboard.sourceViewState = .ready
    dashboard.selectedTab = .report
    dashboard.generatedFeedback = ClassAIPersonalFeedback(
      summaryTitle: "보존할 피드백",
      summaryDetail: "상세",
      points: [],
      nextQuestion: "질문",
      nextHint: "힌트"
    )
    dashboard.generatedInsight = "보존할 인사이트"
    var expectedOpinions = ClassMyOpinionsFeature.State()
    expectedOpinions.opinions = MockClassReport.figmaMyOpinions.resolvedOpinions
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(dashboard))
    state.dashboardInstanceIDs = [dashboard.instanceID]
    let originalRoutes = state.routes
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.view(.myOpinionsTapped)))))
    await store.receive(\.router.routeAction) {
      $0.routes.push(.myOpinions(expectedOpinions))
    }
    #expect(store.state.routes.last == .push(.myOpinions(expectedOpinions)))
    #expect(store.state.routes[2].screen == .ownerDashboard(dashboard))
    #expect(store.state.showsTabBar)

    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.delegate(.openMyOpinions(dashboard.instanceID))))))
    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.delegate(.dismiss)))))
    await store.send(.router(.routeAction(id: 3, action: .myOpinions(.view(.backTapped)))))
    await store.receive(\.router.routeAction)
    await store.receive(\.view.backAction) {
      $0.routes.goBack()
    }
    #expect(store.state.routes == originalRoutes)
    #expect(store.state.showsTabBar)
    await store.finish()
  }

  @Test
  func 운영자_내_의견은_비활성_인스턴스와_준비되지_않은_리포트에서_열리지_않는다() async {
    let room = ClassRoom.mocks[0]
    var dashboard = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    dashboard.report = MockClassReport.figmaMyOpinions
    dashboard.sourceViewState = .ready
    dashboard.selectedTab = .report
    var state = ClassCoordinator.State()
    state.routes.push(.ownerDashboard(dashboard))
    state.dashboardInstanceIDs = [dashboard.instanceID]
    let store = TestStore(initialState: state) { ClassCoordinator() }
    await store.send(.router(.routeAction(id: 1, action: .ownerDashboard(.delegate(.openMyOpinions(UUID()))))))
    await store.finish()

    var inactiveState = state
    inactiveState.routes.push(.myOpinions(.init()))
    let inactiveStore = TestStore(initialState: inactiveState) { ClassCoordinator() }
    await inactiveStore.send(.router(.routeAction(id: 1, action: .ownerDashboard(.delegate(.openMyOpinions(dashboard.instanceID))))))
    await inactiveStore.send(.router(.routeAction(id: 1, action: .ownerDashboard(.delegate(.dismiss)))))
    await inactiveStore.finish()

    dashboard.selectedTab = .home
    state.routes[screenAt: 1] = .ownerDashboard(dashboard)
    let homeStore = TestStore(initialState: state) { ClassCoordinator() }
    await homeStore.send(.router(.routeAction(id: 1, action: .ownerDashboard(.delegate(.openMyOpinions(dashboard.instanceID))))))
    await homeStore.finish()

    dashboard.selectedTab = .report
    dashboard.sourceViewState = .loading
    state.routes[screenAt: 1] = .ownerDashboard(dashboard)
    let loadingStore = TestStore(initialState: state) { ClassCoordinator() }
    await loadingStore.send(.router(.routeAction(id: 1, action: .ownerDashboard(.delegate(.openMyOpinions(dashboard.instanceID))))))
    await loadingStore.finish()

    dashboard.sourceViewState = .ready
    dashboard.management = .init(kind: .management)
    state.routes[screenAt: 1] = .ownerDashboard(dashboard)
    let managementStore = TestStore(initialState: state) { ClassCoordinator() }
    await managementStore.send(.router(.routeAction(id: 1, action: .ownerDashboard(.delegate(.openMyOpinions(dashboard.instanceID))))))
    await managementStore.finish()

    dashboard.management = nil
    dashboard.report = nil
    state.routes[screenAt: 1] = .ownerDashboard(dashboard)
    let missingStore = TestStore(initialState: state) { ClassCoordinator() }
    await missingStore.send(.router(.routeAction(id: 1, action: .ownerDashboard(.delegate(.openMyOpinions(dashboard.instanceID))))))
    await missingStore.finish()
  }

  @Test
  func 클래스_댓글의_리포트는_상세를_보존하고_뒤로가면_탭바를_보인다() async {
    let room = ClassRoom.mockClosedSociety
    let battleID = -1_000_000 - room.id
    var detail = ClassDetailFeature.State(room: room)
    detail.errorMessage = "보존할 상세 상태"
    var state = ClassCoordinator.State()
    state.routes.push(.detail(detail))
    state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    state.chatRoomsByBattleID[battleID] = room
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.view(.chatReportTapped(battleID: battleID)))
    #expect(store.state.routes.count == 3)
    guard case let .detail(preservedDetail) = store.state.routes[1].screen,
          case let .report(report)? = store.state.routes.last?.screen
    else {
      Issue.record("댓글 리포트가 기존 상세 위에 열리지 않음")
      return
    }
    #expect(preservedDetail == detail)
    #expect(report.room == room)
    #expect(store.state.showsTabBar)

    await store.send(.view(.chatReportTapped(battleID: battleID)))
    #expect(store.state.routes.count == 3)
    await store.send(.router(.routeAction(id: 2, action: .report(.delegate(.dismiss)))))
    await store.receive {
      guard case .view(.backAction) = $0 else { return false }
      return true
    }
    #expect(store.state.routes.count == 2)
    guard case let .detail(returnedDetail)? = store.state.routes.last?.screen else {
      Issue.record("리포트 뒤로가기 후 상세로 돌아오지 않음")
      return
    }
    #expect(returnedDetail == detail)
    #expect(store.state.showsTabBar)
  }

  @Test
  func AI_댓글의_리포트는_투표와_AI_채팅_경로를_걷어내고_상세로_돌아온다() async {
    let room = ClassRoom.mockClosedSociety
    let battleID = -1_000_000 - room.id
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.aiVote(.init(room: room, battleID: battleID, instanceID: UUID())))
    state.routes.push(.aiChat(.init(room: room, battleID: battleID, selectedOptionID: 1)))
    state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    state.chatRoomsByBattleID[battleID] = room
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.view(.chatReportTapped(battleID: battleID)))
    #expect(store.state.routes.count == 3)
    guard case .detail = store.state.routes[1].screen,
          case let .report(report)? = store.state.routes.last?.screen
    else {
      Issue.record("AI 경로를 정리한 뒤 리포트가 상세 위에 열리지 않음")
      return
    }
    #expect(report.room == room)
    await store.send(.view(.backAction))
    #expect(store.state.routes.count == 2)
    #expect(store.state.showsTabBar)
  }

  @Test
  func 완료된_AI_투표의_댓글_리포트도_상세로_돌아온다() async {
    let room = ClassRoom.mockClosedSociety
    let battleID = -1_000_000 - room.id
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.aiVote(.init(room: room, battleID: battleID, instanceID: UUID())))
    state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    state.chatRoomsByBattleID[battleID] = room
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.view(.chatReportTapped(battleID: battleID)))
    #expect(store.state.routes.count == 3)
    guard case .report? = store.state.routes.last?.screen else {
      Issue.record("완료된 AI 투표의 댓글 리포트가 열리지 않음")
      return
    }
    await store.send(.view(.backAction))
    #expect(store.state.routes.count == 2)
    #expect(store.state.showsTabBar)
  }

  @Test
  func 운영자_댓글의_리포트는_운영자_대시보드로_열린다() async {
    let room = ClassRoom.mocks[0]
    let battleID = -1_000_000 - room.id
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    state.chatRoomsByBattleID[battleID] = room
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.view(.chatReportTapped(battleID: battleID)))
    #expect(store.state.routes.count == 3)
    guard case let .ownerDashboard(dashboard)? = store.state.routes.last?.screen else {
      Issue.record("운영자 댓글이 운영자 대시보드로 연결되지 않음")
      return
    }
    #expect(dashboard.room == room)
    await store.send(.view(.backAction))
    #expect(store.state.routes.count == 2)
    #expect(store.state.showsTabBar)
  }

  @Test
  func 댓글_리포트는_다른_배틀이나_유효하지_않은_경로에서_열리지_않는다() async {
    let room = ClassRoom.mockClosedSociety
    let battleID = -1_000_000 - room.id
    var valid = ClassCoordinator.State()
    valid.routes.push(.detail(.init(room: room)))
    valid.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    valid.chatRoomsByBattleID[battleID] = room

    await assertChatReportNoOp(valid, battleID: battleID + 1)

    var missingRoom = valid
    missingRoom.chatRoomsByBattleID.removeAll()
    await assertChatReportNoOp(missingRoom, battleID: battleID)

    var mismatchedComment = valid
    mismatchedComment.routes[screenAt: 2] = .chat(.init(route: .comment(battleId: battleID + 1)))
    await assertChatReportNoOp(mismatchedComment, battleID: battleID)

    var missingDetail = ClassCoordinator.State()
    missingDetail.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    missingDetail.chatRoomsByBattleID[battleID] = room
    await assertChatReportNoOp(missingDetail, battleID: battleID)

    var nonComment = valid
    nonComment.routes[screenAt: 2] = .aiVote(.init(room: room, battleID: battleID, instanceID: UUID()))
    await assertChatReportNoOp(nonComment, battleID: battleID)

    var nestedReply = valid
    var chat = ChatCoordinator.State(route: .comment(battleId: battleID))
    chat.routes.push(.commentReply(.init(perspectiveId: 1)))
    nestedReply.routes[screenAt: 2] = .chat(chat)
    await assertChatReportNoOp(nestedReply, battleID: battleID)
  }

  private func assertChatReportNoOp(
    _ state: ClassCoordinator.State,
    battleID: Int
  ) async {
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off
    await store.send(.view(.chatReportTapped(battleID: battleID)))
    #expect(store.state.routes == state.routes)
    #expect(store.state.chatRoomsByBattleID == state.chatRoomsByBattleID)
  }

  @Test
  func 마감된_멤버_배틀은_결과_진입과_리포트로_연결된다() async {
    let room = ClassRoom.mockClosedSociety
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    } withDependencies: {
      $0.uuid = .incrementing
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
    #expect(store.state.showsTabBar)

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
  func 운영자_대시보드는_관리_시트와_전역_마감일_패널에서만_탭바를_숨긴다() async {
    let room = ClassRoom.mocks[0]
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .detail(.delegate(.openReport(room)))
    )))
    #expect(store.state.showsTabBar)
    guard case var .ownerDashboard(dashboard)? = store.state.routes.last?.screen else {
      Issue.record("운영자 대시보드가 열리지 않음")
      return
    }

    var tabBarState = store.state
    dashboard.selectedTab = .report
    tabBarState.routes[screenAt: 2] = .ownerDashboard(dashboard)
    #expect(tabBarState.showsTabBar)

    dashboard.management = .init(kind: .management)
    tabBarState.routes[screenAt: 2] = .ownerDashboard(dashboard)
    #expect(!tabBarState.showsTabBar)

    dashboard.management = nil
    tabBarState.routes[screenAt: 2] = .ownerDashboard(dashboard)
    #expect(tabBarState.showsTabBar)

    tabBarState.deadlineEdit = .init(
      room: room,
      instanceID: UUID(),
      referenceNow: Date(timeIntervalSince1970: 1_760_000_000)
    )
    #expect(!tabBarState.showsTabBar)
    tabBarState.deadlineEdit = nil
    #expect(tabBarState.showsTabBar)

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
    } withDependencies: {
      $0.uuid = .incrementing
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
    myClasses.viewState = .loaded
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(myClasses))
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.members(.init(
      room: room,
      members: originalMembers,
      instanceID: UUID(),
      preloadedViewState: .loaded
    )))

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

  @Test
  func 멤버_보고서가_뒤로가기로_제거되면_진행중인_로드를_취소한다() async {
    let room = ClassRoom.mockClosedSociety
    let useCase = SuspendedClassUseCase()
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.report(.init(room: room, instanceID: UUID())))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classUseCase = useCase
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .report(.async(.fetch)))))
    await useCase.waitForStarts(1)
    await store.send(.view(.backAction))
    await store.finish(timeout: .seconds(1))

    #expect(await useCase.cancelledRequestIDs == [1])
    #expect(store.state.routes.count == 2)
  }

  @Test
  func 스와이프로_멤버_보고서_경로를_제거하면_진행중인_로드를_취소한다() async {
    let room = ClassRoom.mockClosedSociety
    let useCase = SuspendedClassUseCase()
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.report(.init(room: room, instanceID: UUID())))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classUseCase = useCase
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .report(.async(.fetch)))))
    await useCase.waitForStarts(1)
    await store.send(.router(.updateRoutes(Array(store.state.routes.dropLast()))))
    await store.finish(timeout: .seconds(1))

    #expect(await useCase.cancelledRequestIDs == [1])
    #expect(store.state.routes.count == 2)
  }

  @Test
  func 운영자_보고서가_루트로_제거되면_진행중인_로드를_취소한다() async {
    let room = ClassRoom.mocks[0]
    let useCase = SuspendedClassUseCase()
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(.init(room: room, instanceID: UUID())))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classUseCase = useCase
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.async(.fetchDashboard)))))
    await useCase.waitForStarts(1)
    await store.send(.view(.backToRootAction))
    await store.finish(timeout: .seconds(1))

    #expect(await useCase.cancelledRequestIDs == [1])
    #expect(store.state.routes.count == 1)
  }

  @Test(arguments: [true, false])
  func 운영자_보고서_편집은_로드를_유지하고_삭제나_종료는_취소한다(edit: Bool) async {
    let room = ClassRoom.mocks[0]
    let useCase = SuspendedClassUseCase()
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(.init(room: room, instanceID: UUID())))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classUseCase = useCase
      $0.uuid = .incrementing
      $0.date.now = Date(timeIntervalSince1970: 1_760_000_000)
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(.async(.fetchDashboard)))))
    await useCase.waitForStarts(1)
    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(
      .delegate(edit ? .editClass : .deleteClass)
    ))))
    if edit {
      #expect(await useCase.cancelledRequestIDs.isEmpty)
      #expect(store.state.deadlineEdit?.room == room)
      guard case .ownerDashboard? = store.state.routes.last?.screen else {
        Issue.record("마감일 편집 시 운영자 보고서가 유지되지 않음")
        return
      }
      await store.send(.view(.backToRootAction))
    }
    await store.finish(timeout: .seconds(1))

    #expect(await useCase.cancelledRequestIDs == [1])
    if edit {
      #expect(store.state.routes.count == 1)
      #expect(store.state.deadlineEdit == nil)
      return
    }
    guard case .detail? = store.state.routes.last?.screen else {
      Issue.record("운영자 보고서에서 클래스 상세로 돌아가지 않음")
      return
    }
  }

  @Test
  func 같은_방의_보고서_두_개중_제거된_인스턴스의_로드만_취소한다() async throws {
    let room = ClassRoom.mockClosedSociety
    let useCase = SuspendedClassUseCase()
    let firstID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let secondID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.report(.init(room: room, instanceID: firstID)))
    state.routes.push(.report(.init(room: room, instanceID: secondID)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classUseCase = useCase
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .report(.async(.fetch)))))
    await useCase.waitForStarts(1)
    await store.send(.router(.routeAction(id: 3, action: .report(.async(.fetch)))))
    await useCase.waitForStarts(2)
    await store.send(.view(.backAction))
    await useCase.completeReport(requestID: 1)
    await store.receive {
      guard case let .router(.routeAction(id: 2, action: .report(action))) = $0,
            case .inner(.reportResponse) = action else { return false }
      return true
    }
    await store.finish(timeout: .seconds(1))

    #expect(await useCase.cancelledRequestIDs == [2])
    guard case let .report(report)? = store.state.routes.last?.screen else {
      Issue.record("앞선 보고서가 유지되지 않음")
      return
    }
    #expect(report.report == MockClassReport.figma)
  }

  @Test
  func 같은_인덱스의_보고서가_교체되면_이전_인스턴스만_취소한다() async throws {
    let room = ClassRoom.mockClosedSociety
    let useCase = SuspendedClassUseCase()
    let firstID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000003"))
    let replacementID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000004"))
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.report(.init(room: room, instanceID: firstID)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classUseCase = useCase
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 2, action: .report(.async(.fetch)))))
    await useCase.waitForStarts(1)
    var replacementRoutes = store.state.routes
    replacementRoutes[screenAt: 2] = .report(.init(
      room: room,
      instanceID: replacementID
    ))
    await store.send(.router(.updateRoutes(replacementRoutes)))
    await store.send(.router(.routeAction(id: 2, action: .report(.async(.fetch)))))
    await useCase.waitForStarts(2)
    await useCase.completeReport(requestID: 2)
    await store.receive {
      guard case let .router(.routeAction(id: 2, action: .report(action))) = $0,
            case .inner(.reportResponse) = action else { return false }
      return true
    }
    await store.finish(timeout: .seconds(1))

    #expect(await useCase.cancelledRequestIDs == [1])
    guard case let .report(report)? = store.state.routes.last?.screen else {
      Issue.record("교체된 보고서가 유지되지 않음")
      return
    }
    #expect(report.report == MockClassReport.figma)
  }
}

@MainActor
struct ClassNavigationLoadingTests {
  @Test
  func 공유에서_운영자_이름을_push하고_뒤로가면_공유가_남는다() async {
    let room = ClassRoom.mocks[0]
    let instanceID = UUID()
    var state = ClassCoordinator.State()
    state.routes.push(.share(.init(room: room)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classMockRepository = MockClassRepository(rooms: [room])
      $0.uuid = .constant(instanceID)
    }

    await store.send(.router(.routeAction(id: 1, action: .share(.delegate(.nameOwner(room)))))) {
      $0.routes.push(.ownerName(.init(mode: .ownerName, preview: room, instanceID: instanceID)))
      $0.ownerNameInstanceIDs = [instanceID]
    }
    await store.send(.router(.routeAction(id: 1, action: .share(.delegate(.nameOwner(room))))))
    #expect(store.state.routes.count == 3)
    await store.send(.router(.routeAction(id: 2, action: .ownerName(.delegate(.dismiss)))))
    await store.receive(\.view.backAction) {
      $0.routes.goBack()
      $0.ownerNameInstanceIDs = []
    }
    guard case let .share(share)? = store.state.routes.last?.screen else {
      Issue.record("뒤로가기 후 공유 화면이 남아야 합니다")
      return
    }
    #expect(share.room == room)
  }

  @Test
  func 운영자_이름_저장은_현재_인스턴스만_상세로_보낸다() async {
    let room = ClassRoom.mocks[0]
    let oldID = UUID()
    let newID = UUID()
    var owner = ClassJoinFeature.State(mode: .ownerName, preview: room, instanceID: newID)
    owner.preview = nil
    var state = ClassCoordinator.State()
    state.routes.push(.share(.init(room: room)))
    state.routes.push(.ownerName(owner))
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.routeAction(
      id: 2,
      action: .ownerName(.delegate(.ownerNamed(room, instanceID: oldID)))
    ))) {
      $0.ownerNameInstanceIDs = [newID]
    }
    #expect(store.state.routes.count == 3)
    await store.send(.router(.routeAction(
      id: 2,
      action: .ownerName(.delegate(.ownerNamed(room, instanceID: newID)))
    ))) {
      $0.routes.goBackToRoot()
      $0.routes.push(.detail(.init(room: room)))
      $0.ownerNameInstanceIDs = []
    }
    guard case let .detail(detail)? = store.state.routes.last?.screen else {
      Issue.record("운영자 이름 저장 후 클래스 상세가 열려야 합니다")
      return
    }
    #expect(detail.room == room)
  }

  @Test
  func 이전_멤버_요청은_같은_방과_경로_번호로_재진입해도_새_화면에_전달되지_않는다() async {
    let room = ClassRoom.mocks[0]
    let oldID = UUID()
    let newID = UUID()
    let oldRequestID = UUID()
    let newRequestID = UUID()
    var member = ClassMemberFeature.State(room: room, instanceID: newID)
    member.activeLoadRequestID = newRequestID
    member.isLoading = true
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.members(member))
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.inner(.membersLoaded(
      routeID: 2,
      roomID: room.id,
      instanceID: oldID,
      requestID: oldRequestID,
      room: room,
      members: MockClassRepository.figmaOwnerMembers,
      currentMemberID: 1
    ))) {
      $0.memberInstanceIDs = [newID]
    }
    await store.send(.inner(.membersFailed(
      routeID: 2,
      roomID: room.id,
      instanceID: oldID,
      requestID: oldRequestID,
      message: "이전 실패"
    )))
    #expect(store.state.routes.count == 3)
    guard case let .members(current)? = store.state.routes.last?.screen else {
      Issue.record("새 멤버 화면이 유지되어야 합니다")
      return
    }
    #expect(current.activeLoadRequestID == newRequestID)
    #expect(current.members.isEmpty)
  }
}

@MainActor
struct ClassParticipantPushTests {
  @Test
  func 인트로_이용권은_한번만_push하고_닫으면_돌아간다() async {
    let ticketID = UUID(301)
    let store = TestStore(initialState: ClassCoordinator.State()) { ClassCoordinator() } withDependencies: {
      $0.uuid = .constant(ticketID)
    }

    await store.send(.router(.routeAction(id: 0, action: .intro(.delegate(.ticket))))) {
      $0.routes.push(.ticket(.init(instanceID: ticketID)))
      $0.ticketInstanceIDs = [ticketID]
    }
    #expect(store.state.showsTabBar)
    await store.send(.router(.routeAction(id: 0, action: .intro(.delegate(.ticket)))))
    #expect(store.state.routes.count == 2)

    await store.send(.router(.routeAction(id: 1, action: .ticket(.delegate(.dismiss)))))
    await store.receive(\.view.backAction) {
      $0.routes.goBack()
      $0.ticketInstanceIDs = []
    }
  }

  @Test
  func 이용권_확인은_push하고_재등록은_기존_확인_경로를_갱신한다() async throws {
    let firstStart = try #require("2026.10.09".date(as: .yearMonthDayDotted))
    let firstEnd = try #require("2027.04.08".date(as: .yearMonthDayDotted))
    let secondStart = try #require("2026.11.01".date(as: .yearMonthDayDotted))
    let secondEnd = try #require("2027.04.30".date(as: .yearMonthDayDotted))
    let clock = TestClock()
    let originalID = UUID(400)
    var registration = ClassTicketFeature.State(instanceID: originalID)
    registration.phase = .registered
    registration.registrationStartDate = firstStart
    registration.expirationDate = firstEnd
    var state = ClassCoordinator.State()
    state.routes.push(.ticket(registration))
    state.ticketInstanceIDs = [originalID]
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
      $0.continuousClock = clock
      $0.date = .constant(secondStart)
    }

    await store.send(.router(.routeAction(
      id: 1,
      action: .ticket(.delegate(.registrationConfirmed(startDate: firstStart, endDate: firstEnd)))
    )))
    await store.receive(\.inner) {
      var overview = ClassTicketFeature.State(instanceID: UUID(0))
      overview.phase = .overview
      overview.registrationStartDate = firstStart
      overview.expirationDate = firstEnd
      $0.routes.push(.ticket(overview))
      $0.ticketInstanceIDs = [originalID, UUID(0)]
    }
    #expect(store.state.showsTabBar)

    await store.send(.router(.routeAction(
      id: 2,
      action: .ticket(.delegate(.addRegistrationRequested))
    ))) {
      $0.routes.push(.ticket(.init(instanceID: UUID(1))))
      $0.ticketInstanceIDs = [originalID, UUID(0), UUID(1)]
    }
    await store.send(.router(.routeAction(
      id: 3,
      action: .ticket(.binding(.set(\.code, "PICKE30")))
    ))) {
      guard case var .ticket(ticket) = $0.routes[3].screen else { return }
      ticket.code = "PICKE30"
      $0.routes[screenAt: 3] = .ticket(ticket)
    }
    await store.send(.router(.routeAction(
      id: 3,
      action: .ticket(.view(.checkTapped))
    ))) {
      guard case var .ticket(ticket) = $0.routes[3].screen else { return }
      ticket.isChecking = true
      $0.routes[screenAt: 3] = .ticket(ticket)
    }
    await clock.advance(by: .milliseconds(350))
    await store.receive(\.router.routeAction) {
      guard case var .ticket(ticket) = $0.routes[3].screen else { return }
      ticket.isChecking = false
      ticket.phase = .registered
      ticket.registrationStartDate = secondStart
      ticket.expirationDate = secondEnd
      $0.routes[screenAt: 3] = .ticket(ticket)
    }
    await store.receive(\.router.routeAction) {
      guard case var .ticket(overview) = $0.routes[2].screen,
            case var .ticket(original) = $0.routes[1].screen
      else { return }
      overview.registrationStartDate = secondStart
      overview.expirationDate = secondEnd
      original.registrationStartDate = secondStart
      original.expirationDate = secondEnd
      $0.routes[screenAt: 2] = .ticket(overview)
      $0.routes[screenAt: 1] = .ticket(original)
    }
    await store.send(.router(.routeAction(
      id: 3,
      action: .ticket(.delegate(.registrationConfirmed(startDate: secondStart, endDate: secondEnd)))
    )))
    #expect(store.state.routes.count == 4)
    await store.receive(\.inner) {
      $0.routes.goBack()
      guard case var .ticket(overview) = $0.routes[2].screen,
            case var .ticket(original) = $0.routes[1].screen
      else { return }
      overview.registrationStartDate = secondStart
      overview.expirationDate = secondEnd
      original.registrationStartDate = secondStart
      original.expirationDate = secondEnd
      $0.routes[screenAt: 2] = .ticket(overview)
      $0.routes[screenAt: 1] = .ticket(original)
      $0.ticketInstanceIDs = [originalID, UUID(0)]
    }
    #expect(store.state.routes.count == 3)
    await store.send(.view(.backAction)) {
      $0.routes.goBack()
      $0.ticketInstanceIDs = [originalID]
    }
    guard case let .ticket(original) = store.state.routes.last?.screen else {
      Issue.record("뒤로 이동 후 등록 화면이 사라졌습니다")
      return
    }
    #expect(original.periodText == "2026.11.01 – 2027.04.30")
  }

  @Test
  func 이용권_확인_중_스와이프로_경로가_제거되면_응답도_취소된다() async {
    let clock = TestClock()
    let ticketID = UUID(302)
    var ticket = ClassTicketFeature.State(instanceID: ticketID)
    ticket.code = "PICKE30"
    var state = ClassCoordinator.State()
    state.routes.push(.ticket(ticket))
    state.ticketInstanceIDs = [ticketID]
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(Date(timeIntervalSince1970: 0))
    }

    await store.send(.router(.routeAction(id: 1, action: .ticket(.view(.checkTapped))))) {
      guard case var .ticket(current) = $0.routes[1].screen else { return }
      current.isChecking = true
      $0.routes[screenAt: 1] = .ticket(current)
    }
    await store.send(.router(.updateRoutes(Array(state.routes.dropLast())))) {
      $0.routes = Array($0.routes.dropLast())
      $0.ticketInstanceIDs = []
    }
    await clock.advance(by: .milliseconds(350))
    await store.finish(timeout: .seconds(1))
  }

  @Test
  func 추가등록_성공_후_뒤로가도_확인_화면에_새_기간이_남는다() async throws {
    let oldStart = try #require("2026.10.09".date(as: .yearMonthDayDotted))
    let oldEnd = try #require("2027.04.08".date(as: .yearMonthDayDotted))
    let newStart = try #require("2026.11.01".date(as: .yearMonthDayDotted))
    let newEnd = try #require("2027.04.30".date(as: .yearMonthDayDotted))
    var original = ClassTicketFeature.State(instanceID: UUID(400))
    original.phase = .registered
    original.registrationStartDate = oldStart
    original.expirationDate = oldEnd
    var overview = ClassTicketFeature.State(instanceID: UUID(401))
    overview.phase = .overview
    overview.registrationStartDate = oldStart
    overview.expirationDate = oldEnd
    var registration = ClassTicketFeature.State(instanceID: UUID(402))
    registration.phase = .registered
    registration.registrationStartDate = newStart
    registration.expirationDate = newEnd
    var state = ClassCoordinator.State()
    state.routes.push(.ticket(original))
    state.routes.push(.ticket(overview))
    state.routes.push(.ticket(registration))
    state.ticketInstanceIDs = [original.instanceID, overview.instanceID, registration.instanceID]
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.routeAction(
      id: 3,
      action: .ticket(.delegate(.registered(newStart, newEnd)))
    ))) {
      guard case var .ticket(currentOverview) = $0.routes[2].screen,
            case var .ticket(currentOriginal) = $0.routes[1].screen
      else { return }
      currentOverview.registrationStartDate = newStart
      currentOverview.expirationDate = newEnd
      currentOriginal.registrationStartDate = newStart
      currentOriginal.expirationDate = newEnd
      $0.routes[screenAt: 2] = .ticket(currentOverview)
      $0.routes[screenAt: 1] = .ticket(currentOriginal)
    }
    await store.send(.view(.backAction)) {
      $0.routes.goBack()
      $0.ticketInstanceIDs = [original.instanceID, overview.instanceID]
    }
    guard case let .ticket(currentOverview) = store.state.routes.last?.screen else {
      Issue.record("추가등록 뒤 확인 화면이 사라졌습니다")
      return
    }
    #expect(currentOverview.periodText == "2026.11.01 – 2027.04.30")
  }

  @Test
  func 추가등록_조회_중_경로가_제거되면_응답을_취소한다() async throws {
    let start = try #require("2026.10.09".date(as: .yearMonthDayDotted))
    let end = try #require("2027.04.08".date(as: .yearMonthDayDotted))
    let clock = TestClock()
    var original = ClassTicketFeature.State(instanceID: UUID(400))
    original.phase = .registered
    original.registrationStartDate = start
    original.expirationDate = end
    var overview = ClassTicketFeature.State(instanceID: UUID(401))
    overview.phase = .overview
    overview.registrationStartDate = start
    overview.expirationDate = end
    var registration = ClassTicketFeature.State(instanceID: UUID(402))
    registration.code = "PICKE30"
    var state = ClassCoordinator.State()
    state.routes.push(.ticket(original))
    state.routes.push(.ticket(overview))
    state.routes.push(.ticket(registration))
    state.ticketInstanceIDs = [original.instanceID, overview.instanceID, registration.instanceID]
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(start)
    }

    await store.send(.router(.routeAction(id: 3, action: .ticket(.view(.checkTapped))))) {
      guard case var .ticket(current) = $0.routes[3].screen else { return }
      current.isChecking = true
      $0.routes[screenAt: 3] = .ticket(current)
    }
    await store.send(.router(.updateRoutes(Array(state.routes.dropLast())))) {
      $0.routes = Array($0.routes.dropLast())
      $0.ticketInstanceIDs = [original.instanceID, overview.instanceID]
    }
    await clock.advance(by: .milliseconds(350))
    await store.finish(timeout: .seconds(1))
  }

  @Test
  func 인트로_참여는_코드_화면을_한번만_push한다() async {
    let codeID = UUID(201)
    let store = TestStore(initialState: ClassCoordinator.State()) { ClassCoordinator() } withDependencies: {
      $0.uuid = .constant(codeID)
    }

    await store.send(.router(.routeAction(id: 0, action: .intro(.delegate(.join))))) {
      $0.routes.push(.join(.init(mode: .code, instanceID: codeID)))
      $0.participantJoinInstanceIDs = [codeID]
    }
    await store.send(.router(.routeAction(id: 0, action: .intro(.delegate(.join)))))
    #expect(store.state.routes.count == 2)
  }

  @Test
  func 참여_코드_화면에서_새_클래스_만들기를_누르면_방식_선택을_push한다() async {
    let codeID = UUID(205)
    var state = ClassCoordinator.State()
    state.routes.push(.join(.init(mode: .code, instanceID: codeID)))
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.routeAction(id: 1, action: .join(.delegate(.createClassRequested))))) {
      $0.routes.push(.startMethod(.init()))
      $0.participantJoinInstanceIDs = [codeID]
    }
    #expect(store.state.routes.count == 3)
  }

  @Test
  func 이름_입력_화면의_생성_요청은_방식_선택을_열지_않는다() async {
    var state = ClassCoordinator.State()
    state.routes.push(.join(.init(mode: .code, instanceID: UUID(206))))
    state.routes.push(.join(.init(
      mode: .nickname,
      preview: .mockJoinable,
      instanceID: UUID(207)
    )))
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.routeAction(id: 2, action: .join(.delegate(.createClassRequested)))))
    #expect(store.state.routes.count == 3)
  }

  @Test
  func 코드_조회_성공은_이름_화면을_push하고_중복응답은_무시한다() async {
    let preview = ClassJoinPreview(room: .mockJoinable)
    let codeID = UUID(202)
    let nicknameID = UUID(203)
    var state = ClassCoordinator.State()
    state.routes.push(.join(.init(mode: .code, instanceID: codeID)))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .constant(nicknameID)
    }

    await store.send(.router(.routeAction(id: 1, action: .join(.delegate(.found(
      preview,
      instanceID: codeID
    )))))) {
      $0.routes.push(.join(.init(mode: .nickname, preview: preview, instanceID: nicknameID)))
      $0.participantJoinInstanceIDs = [codeID, nicknameID]
    }
    await store.send(.router(.routeAction(id: 1, action: .join(.delegate(.found(
      preview,
      instanceID: codeID
    ))))))
    #expect(store.state.routes.count == 3)
    await store.send(.router(.routeAction(id: 2, action: .join(.delegate(.dismiss)))))
    await store.receive(\.view.backAction) {
      $0.routes.goBack()
      $0.participantJoinInstanceIDs = [codeID]
    }
    await store.send(.router(.routeAction(id: 1, action: .join(.delegate(.dismiss)))))
    await store.receive(\.view.backAction) {
      $0.routes.goBack()
      $0.participantJoinInstanceIDs = []
    }
  }

  @Test
  func 잘못된_참여완료_델리게이트는_뒤로가기를_막지_않는다() async {
    let room = ClassRoom.mockJoinable
    let nicknameID = UUID(204)
    var state = ClassCoordinator.State()
    state.routes.push(.join(.init(mode: .nickname, instanceID: nicknameID)))
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.routeAction(id: 1, action: .join(.delegate(.joined(
      room,
      nickname: "민지",
      instanceID: nicknameID
    )))))) {
      $0.participantJoinInstanceIDs = [nicknameID]
    }
    #expect(store.state.pendingJoinID == nil)
    await store.send(.router(.routeAction(id: 1, action: .join(.delegate(.dismiss)))))
    await store.receive(\.view.backAction) {
      $0.routes.goBack()
      $0.participantJoinInstanceIDs = []
    }
  }

  @Test
  func 참여확정_후_스와이프한_경로는_복원하지_않고_상세로_전환한다() async {
    let room = ClassRoom.mockJoinable
    let codeID = UUID(205)
    let nicknameID = UUID(206)
    let requestID = UUID(207)
    var state = ClassCoordinator.State()
    state.routes.push(.join(.init(mode: .code, instanceID: codeID)))
    state.routes.push(.join(.init(mode: .nickname, instanceID: nicknameID)))
    state.pendingJoinID = requestID
    state.completingJoinCodeInstanceID = codeID
    state.completingJoinNicknameInstanceID = nicknameID
    state.participantJoinInstanceIDs = [codeID, nicknameID]
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.routeAction(id: 2, action: .join(.view(.joinTapped)))))
    #expect(store.state.pendingJoinID == requestID)
    await store.send(.router(.routeAction(id: 2, action: .join(.delegate(.dismiss)))))
    await store.send(.router(.updateRoutes(Array(store.state.routes.dropLast())))) {
      $0.routes = Array($0.routes.dropLast())
      $0.participantJoinInstanceIDs = [codeID]
    }
    #expect(store.state.routes.count == 2)
    await store.send(.inner(.joinedSessionCleared(requestID, room))) {
      $0.pendingJoinID = nil
      $0.completingJoinCodeInstanceID = nil
      $0.completingJoinNicknameInstanceID = nil
      $0.routes.goBackToRoot()
      $0.routes.push(.detail(.init(room: room)))
      $0.participantJoinInstanceIDs = []
    }
  }

  @Test
  func 참여확정_정리중_이름_화면을_스와이프해도_코드_재검색은_정리를_취소하지_못한다() async {
    let room = ClassRoom.mockJoinable
    let codeID = UUID(211)
    let nicknameID = UUID(212)
    let requestID = UUID(213)
    var code = ClassJoinFeature.State(mode: .code, instanceID: codeID)
    code.joinCode = room.joinCode
    var state = ClassCoordinator.State()
    state.routes.push(.join(code))
    state.routes.push(.join(.init(mode: .nickname, instanceID: nicknameID)))
    state.pendingJoinID = requestID
    state.completingJoinCodeInstanceID = codeID
    state.completingJoinNicknameInstanceID = nicknameID
    state.participantJoinInstanceIDs = [codeID, nicknameID]
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.router(.updateRoutes(Array(state.routes.dropLast())))) {
      $0.routes = Array($0.routes.dropLast())
      $0.participantJoinInstanceIDs = [codeID]
    }
    await store.send(.router(.routeAction(id: 1, action: .join(.view(.findTapped)))))
    await store.send(.router(.routeAction(id: 1, action: .join(.async(.find(room.joinCode))))))
    #expect(store.state.pendingJoinID == requestID)
    guard case let .join(currentCode)? = store.state.routes.last?.screen else {
      Issue.record("코드 화면이 유지되지 않았습니다.")
      return
    }
    #expect(currentCode.activeFindRequestID == nil)

    await store.send(.inner(.joinedSessionCleared(requestID, room))) {
      $0.pendingJoinID = nil
      $0.completingJoinCodeInstanceID = nil
      $0.completingJoinNicknameInstanceID = nil
      $0.routes.goBackToRoot()
      $0.routes.push(.detail(.init(room: room)))
      $0.participantJoinInstanceIDs = []
    }
  }

  @Test
  func 명시적으로_루트에_돌아오면_늦은_참여완료는_상세를_열지_않는다() async {
    let room = ClassRoom.mockJoinable
    let codeID = UUID(208)
    let nicknameID = UUID(209)
    let requestID = UUID(210)
    var state = ClassCoordinator.State()
    state.routes.push(.join(.init(mode: .code, instanceID: codeID)))
    state.routes.push(.join(.init(mode: .nickname, instanceID: nicknameID)))
    state.pendingJoinID = requestID
    state.completingJoinCodeInstanceID = codeID
    state.completingJoinNicknameInstanceID = nicknameID
    state.participantJoinInstanceIDs = [codeID, nicknameID]
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.view(.backToRootAction)) {
      $0.pendingJoinID = nil
      $0.completingJoinCodeInstanceID = nil
      $0.completingJoinNicknameInstanceID = nil
      $0.routes.goBackToRoot()
      $0.participantJoinInstanceIDs = []
    }
    await store.send(.inner(.joinedSessionCleared(requestID, room)))
    #expect(store.state.routes.count == 1)
  }
}

@MainActor
struct ClassDeadlineSheetCoordinatorTests {
  @Test
  func 마감일_저장_후_늦은_멤버_조회는_새_마감일과_화면_인스턴스를_보존한다() async throws {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room], availableRooms: [])
    let updated = try await repository.updateDeadline(
      id: room.id,
      deadline: room.deadline.addingTimeInterval(86400)
    )
    let memberInstanceID = UUID()
    let loadRequestID = UUID()
    var member = ClassMemberFeature.State(room: room, instanceID: memberInstanceID)
    member.activeLoadRequestID = loadRequestID
    member.isLoading = true
    var editor = ClassDeadlineEditFeature.State(
      room: room,
      instanceID: UUID(),
      referenceNow: Date(timeIntervalSince1970: 1_760_000_000)
    )
    let saveRequestID = UUID()
    editor.activeRequestID = saveRequestID
    editor.isSaving = true
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.members(member))
    state.deadlineEdit = editor
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.deadlineEdit(.presented(.delegate(.saved(
      updated,
      instanceID: editor.instanceID,
      requestID: saveRequestID
    )))))
    await store.send(.inner(.membersLoaded(
      routeID: 2,
      roomID: room.id,
      instanceID: memberInstanceID,
      requestID: loadRequestID,
      room: room,
      members: MockClassRepository.figmaOwnerMembers,
      currentMemberID: 1
    )))
    await store.receive {
      guard case .router(.routeAction(id: 2, action: .members(.membersLoaded))) = $0 else { return false }
      return true
    }
    await store.finish()

    guard case let .members(current)? = store.state.routes.last?.screen else {
      Issue.record("늦은 응답 뒤에도 멤버 화면이 유지되어야 합니다.")
      return
    }
    #expect(current.instanceID == memberInstanceID)
    #expect(current.room == updated)
    #expect(current.members == MockClassRepository.figmaOwnerMembers)
    #expect(current.activeLoadRequestID == nil)
    #expect(store.state.deadlineEdit == nil)
  }

  @Test
  func 목록에서_연_상세는_서버_상세로_갱신한다() async {
    let room = ClassRoom.mocks[0]
    let projection = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: "",
      battle: room.battle,
      deadline: room.deadline,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: false,
      requiresComment: false
    )
    var list = MyClassFeature.State()
    list.rooms = [projection]
    list.viewState = .loaded
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(list))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classUseCase = MockClassRepository(rooms: [room], availableRooms: [])
      $0.uuid = .incrementing
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 1,
      action: .myClasses(.delegate(.openRoom(projection)))
    )))
    guard case let .detail(pending)? = store.state.routes.last?.screen,
          let requestID = pending.activeLoadRequestID
    else {
      Issue.record("상세 조회가 시작되지 않음")
      return
    }
    #expect(pending.viewState == .loading)
    await store.receive(\.inner, .detailLoaded(
      routeID: 2,
      roomID: room.id,
      instanceID: pending.instanceID,
      requestID: requestID,
      room: room
    ))
    guard case let .detail(loaded)? = store.state.routes.last?.screen else {
      Issue.record("상세 경로가 유지되지 않음")
      return
    }
    #expect(loaded.viewState == .loaded)
    #expect(loaded.room.joinCode == room.joinCode)
    #expect(loaded.room.requiresComment == room.requiresComment)
  }

  @Test
  func 교체된_상세_경로는_이전_조회_응답을_무시한다() async {
    let room = ClassRoom.mocks[0]
    var oldDetail = ClassDetailFeature.State(room: room)
    let requestID = UUID()
    oldDetail.viewState = .loading
    oldDetail.activeLoadRequestID = requestID
    let newDetail = ClassDetailFeature.State(room: room)
    var state = ClassCoordinator.State()
    state.routes.push(.detail(newDetail))
    let store = TestStore(initialState: state) { ClassCoordinator() }

    await store.send(.inner(.detailLoaded(
      routeID: 1,
      roomID: room.id,
      instanceID: oldDetail.instanceID,
      requestID: requestID,
      room: room
    )))
    #expect(store.state.routes[1].screen == .detail(newDetail))
  }

  @Test
  func 세_화면에서_현재_경로를_유지하며_마감일_시트를_연다() async {
    let room = ClassRoom.mocks[0]
    var list = MyClassFeature.State()
    list.rooms = [room]
    list.viewState = .loaded
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(list))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
      $0.date.now = Date(timeIntervalSince1970: 1_760_000_000)
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 1, action: .myClasses(.delegate(.openInformation(room))))))
    await store.receive(\.inner, .deadlineDetailResponse(
      routeID: 1,
      roomID: room.id,
      .success(room)
    ))
    #expect(store.state.routes.count == 2)
    #expect(store.state.deadlineEdit?.room == room)

    await store.send(.deadlineEdit(.dismiss))
    await store.send(.router(.routeAction(id: 1, action: .myClasses(.delegate(.openRoom(room))))))
    await store.send(.router(.routeAction(id: 2, action: .detail(.delegate(.openDeadline(room))))))
    #expect(store.state.routes.count == 3)
    #expect(store.state.deadlineEdit?.room == room)

    await store.send(.deadlineEdit(.dismiss))
    await store.send(.router(.routeAction(id: 2, action: .detail(.delegate(.openReport(room))))))
    await store.send(.router(.routeAction(id: 3, action: .ownerDashboard(.delegate(.editClass)))))
    #expect(store.state.routes.count == 4)
    #expect(store.state.deadlineEdit?.room == room)
  }

  @Test
  func 저장중_닫기와_뒤로가기와_시트_교체를_차단한다() async {
    let room = ClassRoom.mocks[0]
    var editor = ClassDeadlineEditFeature.State(
      room: room,
      instanceID: UUID(),
      referenceNow: Date(timeIntervalSince1970: 1_760_000_000)
    )
    editor.isSaving = true
    editor.activeRequestID = UUID()
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.deadlineEdit = editor
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.deadlineEdit(.dismiss))
    await store.send(.view(.backAction))
    await store.send(.view(.backToRootAction))
    await store.send(.router(.routeAction(id: 1, action: .detail(.delegate(.openDeadline(room))))))
    #expect(store.state.deadlineEdit?.instanceID == editor.instanceID)
    #expect(store.state.routes.count == 2)
  }

  @Test
  func 유효한_저장만_시트를_닫고_같은_방_사본을_갱신한다() async throws {
    let room = ClassRoom.mocks[0]
    let other = ClassRoom.mocks[1]
    let repository = MockClassRepository(rooms: [room, other], availableRooms: [])
    let updated = try await repository.updateDeadline(id: room.id, deadline: room.deadline.addingTimeInterval(86400))
    var list = MyClassFeature.State()
    list.rooms = [room, other]
    list.viewState = .loaded
    var dashboard = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    dashboard.selectedTab = .report
    var editor = ClassDeadlineEditFeature.State(
      room: room,
      instanceID: UUID(),
      referenceNow: Date(timeIntervalSince1970: 1_760_000_000)
    )
    editor.isSaving = true
    editor.activeRequestID = UUID()
    let requestID = try #require(editor.activeRequestID)
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(list))
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.ownerDashboard(dashboard))
    state.chatRoomsByBattleID[99] = room
    state.chatRoomsByBattleID[100] = other
    state.deadlineEdit = editor
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.deadlineEdit(.presented(.delegate(.saved(
      updated,
      instanceID: UUID(),
      requestID: requestID
    )))))
    #expect(store.state.deadlineEdit?.instanceID == editor.instanceID)

    await store.send(.deadlineEdit(.presented(.delegate(.saved(
      updated,
      instanceID: editor.instanceID,
      requestID: requestID
    )))))
    #expect(store.state.deadlineEdit == nil)
    guard case let .myClasses(updatedList) = store.state.routes[1].screen,
          case let .detail(updatedDetail) = store.state.routes[2].screen,
          case let .ownerDashboard(updatedDashboard) = store.state.routes[3].screen
    else {
      Issue.record("경로가 유지되지 않았습니다.")
      return
    }
    #expect(updatedList.rooms == [updated, other])
    #expect(updatedDetail.room == updated)
    #expect(updatedDetail.room.deadline == updated.deadline)
    #expect(updatedDashboard.room == updated)
    #expect(updatedDashboard.instanceID == dashboard.instanceID)
    #expect(updatedDashboard.selectedTab == .report)
    #expect(store.state.chatRoomsByBattleID[99] == updated)
    #expect(store.state.chatRoomsByBattleID[100] == other)
  }

  @Test
  func 마감일_저장_결과가_마지막_표시_방을_제외하면_목록을_empty로_전환한다() async {
    let room = ClassRoom.mocks[0]
    let closed = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: room.deadline.addingTimeInterval(86400),
      memberCount: room.memberCount,
      role: room.role,
      status: .closed,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment,
      ownerParticipates: room.ownerParticipates,
      memberCapacity: room.memberCapacity
    )
    var list = MyClassFeature.State()
    list.rooms = [room]
    list.progress = .open
    list.viewState = .loaded
    var editor = ClassDeadlineEditFeature.State(
      room: room,
      instanceID: UUID(),
      referenceNow: Date(timeIntervalSince1970: 1_760_000_000)
    )
    let requestID = UUID()
    editor.activeRequestID = requestID
    editor.isSaving = true
    var state = ClassCoordinator.State()
    state.routes.push(.myClasses(list))
    state.deadlineEdit = editor
    let store = TestStore(initialState: state) { ClassCoordinator() }
    store.exhaustivity = .off

    await store.send(.deadlineEdit(.presented(.delegate(.saved(
      closed,
      instanceID: editor.instanceID,
      requestID: requestID
    )))))
    guard case let .myClasses(updatedList)? = store.state.routes.last?.screen else {
      Issue.record("목록 경로가 유지되지 않았습니다.")
      return
    }
    #expect(updatedList.rooms == [closed])
    #expect(updatedList.visibleRooms.isEmpty)
    #expect(updatedList.viewState == .empty)
  }
}

@MainActor
struct ChatPlayerLifecycleTests {
  private enum ClassExit: CaseIterable, Sendable {
    case back
    case root
    case interactivePop
    case replaceWithAIChat
    case replaceWithRecommend
  }

  @Test(arguments: ClassExit.allCases)
  private func 클래스_채팅_경로가_제거되면_재생시간_구독이_끝난다(exit: ClassExit) async {
    let room = ClassRoom.mocks[0]
    let player = ControlledClassAudioPlayer()
    var chat = ChatCoordinator.State(battleId: 101)
    chat.routes.push(.chatRoom(.init(battleId: 101)))
    guard case let .chatRoom(chatRoom)? = chat.routes.last?.screen else {
      Issue.record("채팅방 경로를 만들지 못했습니다")
      return
    }
    let instanceID = chatRoom.instanceID
    var state = ClassCoordinator.State()
    state.routes.push(.detail(.init(room: room)))
    state.routes.push(.chat(chat))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.audioPlayer = player
    }

    await store.send(.router(.routeAction(id: 2, action: .chat(.router(.routeAction(
      id: 1,
      action: .chatRoom(.async(.subscribePlayer))
    )))))) {
      $0.chatRoomInstanceIDs = [instanceID]
      $0.routes[screenAt: 2] = .chat({
        var updated = chat
        updated.observedChatRoomInstanceIDs = [instanceID]
        return updated
      }())
    }
    #expect(await player.waitForSubscriptions(1))
    #expect(await player.recordedPlaybackRates() == [1])
    #expect(await player.yield(1.25, to: 0))
    await store.receive {
      if case .router(.routeAction(id: 2, action: .chat(.router(.routeAction(
        id: 1,
        action: .chatRoom(.inner(.playerTimeUpdated(1.25)))
      ))))) = $0 {
        return true
      }
      return false
    } assert: {
      guard case var .chat(updatedChat) = $0.routes[2].screen,
            case var .chatRoom(updatedRoom) = updatedChat.routes[1].screen
      else { return }
      updatedRoom.currentTime = 1.25
      updatedChat.routes[screenAt: 1] = .chatRoom(updatedRoom)
      $0.routes[screenAt: 2] = .chat(updatedChat)
    }

    switch exit {
    case .back:
      await store.send(.view(.backAction)) {
        $0.routes.goBack()
        $0.chatRoomInstanceIDs = []
      }
    case .root:
      await store.send(.view(.backToRootAction)) {
        $0.routes.goBackToRoot()
        $0.chatRoomInstanceIDs = []
      }
    case .interactivePop:
      await store.send(.router(.updateRoutes(Array(store.state.routes.dropLast())))) {
        $0.routes = Array($0.routes.dropLast())
        $0.chatRoomInstanceIDs = []
      }
    case .replaceWithAIChat, .replaceWithRecommend:
      var routes = store.state.routes
      if exit == .replaceWithAIChat {
        routes[screenAt: 2] = .aiChat(.init(room: room, battleID: 101, selectedOptionID: 1))
      } else {
        routes[screenAt: 2] = .recommend(.init(filter: .init(), mode: .aiQuestions))
      }
      await store.send(.router(.updateRoutes(routes))) {
        $0.routes = routes
        $0.chatRoomInstanceIDs = []
      }
    }
    #expect(await player.waitForTerminations(1))
    #expect(await player.isTerminated(0))
    await store.finish(timeout: .seconds(1))
  }

  @Test
  func 클래스_안의_채팅방만_닫아도_구독이_끝난다() async {
    let player = ControlledClassAudioPlayer()
    var chat = ChatCoordinator.State(battleId: 104)
    chat.routes.push(.chatRoom(.init(battleId: 104)))
    guard case let .chatRoom(room)? = chat.routes.last?.screen else {
      Issue.record("채팅방 경로를 만들지 못했습니다")
      return
    }
    var state = ClassCoordinator.State()
    state.routes.push(.chat(chat))
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.audioPlayer = player
    }
    await store.send(.router(.routeAction(id: 1, action: .chat(.router(.routeAction(
      id: 1,
      action: .chatRoom(.async(.subscribePlayer))
    )))))) {
      $0.chatRoomInstanceIDs = [room.instanceID]
      var updated = chat
      updated.observedChatRoomInstanceIDs = [room.instanceID]
      $0.routes[screenAt: 1] = .chat(updated)
    }
    #expect(await player.waitForSubscriptions(1))
    await store.send(.router(.routeAction(id: 1, action: .chat(.view(.backAction))))) {
      $0.chatRoomInstanceIDs = []
      guard case var .chat(updated) = $0.routes[1].screen else { return }
      updated.routes.goBack()
      updated.observedChatRoomInstanceIDs = []
      $0.routes[screenAt: 1] = .chat(updated)
    }
    #expect(await player.waitForTerminations(1))
    #expect(await player.isTerminated(0))
    #expect(store.state.routes.count == 2)
    await store.finish(timeout: .seconds(1))
  }

  @Test
  func 채팅_코디네이터의_내부_뒤로가기와_스와이프도_구독을_끝낸다() async {
    for interactive in [false, true] {
      let player = ControlledClassAudioPlayer()
      var state = ChatCoordinator.State(battleId: 102)
      state.routes.push(.chatRoom(.init(battleId: 102)))
      guard case let .chatRoom(room)? = state.routes.last?.screen else {
        Issue.record("채팅방 경로를 만들지 못했습니다")
        return
      }
      let store = TestStore(initialState: state) { ChatCoordinator() } withDependencies: {
        $0.audioPlayer = player
      }
      await store.send(.router(.routeAction(id: 1, action: .chatRoom(.async(.subscribePlayer))))) {
        $0.observedChatRoomInstanceIDs = [room.instanceID]
      }
      #expect(await player.waitForSubscriptions(1))
      if interactive {
        await store.send(.router(.updateRoutes(Array(state.routes.dropLast())))) {
          $0.routes = Array($0.routes.dropLast())
          $0.observedChatRoomInstanceIDs = []
        }
      } else {
        await store.send(.view(.backAction)) {
          $0.routes.goBack()
          $0.observedChatRoomInstanceIDs = []
        }
      }
      #expect(await player.waitForTerminations(1))
      #expect(await player.isTerminated(0))
      await store.finish(timeout: .seconds(1))
    }
  }

  @Test
  func 새_채팅방_구독은_이전_구독만_대체하고_이전_경로_정리는_새_구독을_보존한다() async {
    let player = ControlledClassAudioPlayer()
    var state = ChatCoordinator.State(battleId: 103)
    state.routes.push(.chatRoom(.init(battleId: 103)))
    state.routes.push(.chatRoom(.init(battleId: 103)))
    guard case let .chatRoom(first) = state.routes[1].screen,
          case let .chatRoom(second) = state.routes[2].screen
    else {
      Issue.record("서로 다른 채팅방 인스턴스를 만들지 못했습니다")
      return
    }
    #expect(first.instanceID != second.instanceID)
    let store = TestStore(initialState: state) { ChatCoordinator() } withDependencies: {
      $0.audioPlayer = player
    }
    await store.send(.router(.routeAction(id: 1, action: .chatRoom(.async(.subscribePlayer))))) {
      $0.observedChatRoomInstanceIDs = [first.instanceID, second.instanceID]
    }
    #expect(await player.waitForSubscriptions(1))
    await store.send(.router(.routeAction(id: 2, action: .chatRoom(.async(.subscribePlayer)))))
    #expect(await player.waitForSubscriptions(2))
    #expect(await player.waitForTerminations(1))
    #expect(await player.isTerminated(0))
    var survivingRoutes = store.state.routes
    survivingRoutes[screenAt: 1] = .preVote(.init(battleId: 103))
    await store.send(.router(.updateRoutes(survivingRoutes))) {
      $0.routes = survivingRoutes
      $0.observedChatRoomInstanceIDs = [second.instanceID]
    }
    #expect(await player.yield(2.0, to: 1))
    await store.receive {
      if case .router(.routeAction(id: 2, action: .chatRoom(.inner(.playerTimeUpdated(2.0))))) = $0 {
        return true
      }
      return false
    } assert: {
      guard case var .chatRoom(room) = $0.routes[2].screen else { return }
      room.currentTime = 2.0
      $0.routes[screenAt: 2] = .chatRoom(room)
    }
    await store.send(.view(.backToRootAction)) {
      $0.routes.goBackToRoot()
      $0.observedChatRoomInstanceIDs = []
    }
    #expect(await player.waitForTerminations(2))
    #expect(await player.isTerminated(1))
    await store.finish(timeout: .seconds(1))
  }

  @Test
  func 클래스_탭_재선택은_클래스_루트_액션으로_전달된다() async {
    var state = MainTabCoordinator.State(selectedTab: MainTabCoordinator.Tab.classroom.rawValue)
    state.classState.routes.push(.detail(.init(room: ClassRoom.mocks[0])))
    let store = TestStore(initialState: state) { MainTabCoordinator() }
    await store.send(.tabReselected(MainTabCoordinator.Tab.classroom.rawValue))
    await store.receive {
      if case .classroom(.view(.backToRootAction)) = $0 {
        return true
      }
      return false
    } assert: {
      $0.classState.routes.goBackToRoot()
    }
    await store.finish(timeout: .seconds(1))
  }
}

private actor ControlledClassAudioPlayer: AudioPlayerInterface {
  private var continuations: [UUID: AsyncStream<TimeInterval>.Continuation] = [:]
  private var subscriptionIDs: [UUID] = []
  private var terminatedIDs: Set<UUID> = []

  nonisolated func currentTimes() -> AsyncStream<TimeInterval> {
    AsyncStream { continuation in
      let id = UUID()
      continuation.onTermination = { @Sendable _ in Task { await self.terminate(id) } }
      Task { await self.subscribe(id, continuation: continuation) }
    }
  }

  func load(url _: URL) async -> Bool {
    true
  }

  func play() async {}
  func pause() async {}
  func setPlaybackRate(_ rate: Float) async {
    playbackRates.append(rate)
  }
  func seek(to _: TimeInterval) async {}
  func duration() async -> TimeInterval {
    0
  }

  private var playbackRates: [Float] = []

  func recordedPlaybackRates() -> [Float] {
    playbackRates
  }

  func waitForSubscriptions(_ count: Int) async -> Bool {
    for _ in 0 ..< 100 {
      if subscriptionIDs.count >= count {
        return true
      }
      try? await Task.sleep(for: .milliseconds(10))
    }
    return false
  }

  func waitForTerminations(_ count: Int) async -> Bool {
    for _ in 0 ..< 100 {
      if terminatedIDs.count >= count {
        return true
      }
      try? await Task.sleep(for: .milliseconds(10))
    }
    return false
  }

  func yield(_ time: TimeInterval, to index: Int) -> Bool {
    guard subscriptionIDs.indices.contains(index),
          let continuation = continuations[subscriptionIDs[index]]
    else { return false }
    if case .enqueued = continuation.yield(time) {
      return true
    }
    return false
  }

  func isTerminated(_ index: Int) -> Bool {
    guard subscriptionIDs.indices.contains(index),
          let continuation = continuations[subscriptionIDs[index]],
          terminatedIDs.contains(subscriptionIDs[index])
    else { return false }
    if case .terminated = continuation.yield(-1) {
      return true
    }
    return false
  }

  private func subscribe(
    _ id: UUID,
    continuation: AsyncStream<TimeInterval>.Continuation
  ) {
    subscriptionIDs.append(id)
    continuations[id] = continuation
  }

  private func terminate(_ id: UUID) {
    terminatedIDs.insert(id)
  }
}

private actor SuspendedClassUseCase: ClassInterface {
  private let repository = MockClassRepository()
  private var nextRequestID = 0
  private var reportRequests: [Int: CheckedContinuation<ClassReport?, Error>] = [:]
  private var dashboardRequests: [Int: CheckedContinuation<ClassOwnerDashboardData?, Error>] = [:]
  private var startedCount = 0
  private var startWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
  private(set) var cancelledRequestIDs: [Int] = []

  func waitForStarts(_ count: Int) async {
    guard startedCount < count else { return }
    await withCheckedContinuation { continuation in
      startWaiters.append((count, continuation))
    }
  }

  func completeReport(requestID: Int) {
    reportRequests.removeValue(forKey: requestID)?.resume(returning: MockClassReport.figma)
  }

  private func nextID() -> Int {
    nextRequestID += 1
    return nextRequestID
  }

  private func didStart() {
    startedCount += 1
    let ready = startWaiters.filter { startedCount >= $0.0 }
    startWaiters.removeAll { startedCount >= $0.0 }
    for (_, continuation) in ready {
      continuation.resume()
    }
  }

  private func cancelReport(_ id: Int) {
    guard let continuation = reportRequests.removeValue(forKey: id) else { return }
    cancelledRequestIDs.append(id)
    continuation.resume(throwing: CancellationError())
  }

  private func cancelDashboard(_ id: Int) {
    guard let continuation = dashboardRequests.removeValue(forKey: id) else { return }
    cancelledRequestIDs.append(id)
    continuation.resume(throwing: CancellationError())
  }

  func fetchReport(roomID _: Int) async throws -> ClassReport? {
    let id = nextID()
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        reportRequests[id] = continuation
        didStart()
      }
    } onCancel: {
      Task { await self.cancelReport(id) }
    }
  }

  func fetchOwnerDashboard(roomID _: Int) async throws -> ClassOwnerDashboardData? {
    let id = nextID()
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        dashboardRequests[id] = continuation
        didStart()
      }
    } onCancel: {
      Task { await self.cancelDashboard(id) }
    }
  }

  func fetchMyClasses() async throws -> [ClassRoom] {
    try await repository.fetchMyClasses()
  }

  func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    try await repository.fetchRecommendedBattles(filter: filter)
  }

  func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    try await repository.createClass(creation)
  }

  func fetchClass(joinCode: String) async throws -> ClassRoom {
    try await repository.fetchClass(joinCode: joinCode)
  }

  func fetchClass(id: Int) async throws -> ClassRoom {
    try await repository.fetchClass(id: id)
  }

  func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    try await repository.joinClass(joinCode: joinCode, nickname: nickname)
  }

  func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    try await repository.updateDeadline(id: id, deadline: deadline)
  }

  func deleteClass(id: Int) async throws {
    try await repository.deleteClass(id: id)
  }

  func leaveClass(id: Int) async throws {
    try await repository.leaveClass(id: id)
  }
}
