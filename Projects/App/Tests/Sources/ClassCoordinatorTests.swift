//
//  ClassCoordinatorTests.swift
//  PickeTests
//
//  Created by Picke on 10/11/26.
//

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
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.classMockChatSession = session
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 0, action: .intro(.delegate(.joined(room, nickname: "새 이름"))))))
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
    var dashboard = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
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
    let store = TestStore(initialState: state) {
      ClassCoordinator()
    } withDependencies: {
      $0.classUseCase = repository
      $0.uuid = .incrementing
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
    #expect(dashboard.hasLoaded)
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
  func 클래스_댓글의_리포트는_상세를_보존하고_뒤로가면_탭바를_보인다() async {
    let room = ClassRoom.mockClosedSociety
    let battleID = -1_000_000 - room.id
    var detail = ClassDetailFeature.State(room: room)
    detail.errorMessage = "보존할 상세 상태"
    var state = ClassCoordinator.State()
    state.routes.push(.detail(detail))
    state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    state.chatRoomsByBattleID[battleID] = room
    let store = TestStore(initialState: state) { ClassCoordinator() }
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
    #expect(!store.state.showsTabBar)

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
    state.routes.push(.aiVote(.init(room: room, battleID: battleID)))
    state.routes.push(.aiChat(.init(room: room, battleID: battleID, selectedOptionID: 1)))
    state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    state.chatRoomsByBattleID[battleID] = room
    let store = TestStore(initialState: state) { ClassCoordinator() }
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
    state.routes.push(.aiVote(.init(room: room, battleID: battleID)))
    state.routes.push(.chat(.init(route: .comment(battleId: battleID))))
    state.chatRoomsByBattleID[battleID] = room
    let store = TestStore(initialState: state) { ClassCoordinator() }
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
    let store = TestStore(initialState: state) { ClassCoordinator() }
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
    nonComment.routes[screenAt: 2] = .aiVote(.init(room: room, battleID: battleID))
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
    let store = TestStore(initialState: state) { ClassCoordinator() } withDependencies: {
      $0.uuid = .incrementing
    }
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
  func 운영자_보고서에서_수정이나_삭제로_돌아가면_로드를_취소한다(edit: Bool) async {
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
    await store.send(.router(.routeAction(id: 2, action: .ownerDashboard(
      .delegate(edit ? .editClass : .deleteClass)
    ))))
    await store.finish(timeout: .seconds(1))

    #expect(await useCase.cancelledRequestIDs == [1])
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
