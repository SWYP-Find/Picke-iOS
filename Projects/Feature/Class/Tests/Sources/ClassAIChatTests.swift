//
//  ClassAIChatTests.swift
//  ClassTests
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassAIChatTests {
  private struct DebateStub: ClassDebateInterface {
    let debate: ClassDebate
    var hasExistingSession = true
    var spy: DebateSpy?

    func fetch(classID _: Int) async throws -> ClassDebate {
      if !hasExistingSession {
        throw ClassAIChatError.noSession
      }
      return debate
    }

    func start(classID _: Int) async throws -> ClassDebate {
      debate
    }

    func submitReply(
      classID _: Int,
      round: Int,
      content: String,
      requestKey: UUID
    ) async throws -> ClassDebate {
      await spy?.record(round: round, content: content, requestKey: requestKey)
      return debate
    }

    func retry(classID _: Int) async throws -> ClassDebate {
      debate
    }
  }

  private func debate(
    status: ClassDebate.Status = .waitingUser,
    canReply: Bool = true,
    canRetry: Bool = false,
    round: Int = 1
  ) -> ClassDebate {
    ClassDebate(
      sessionID: 7,
      status: status,
      round: round,
      canReply: canReply,
      canRetry: canRetry,
      philosopherName: "칸트",
      participantOptionTitle: "창작이다",
      opponentOptionTitle: "창작이 아니다",
      messages: [.init(id: 101, round: 1, speaker: .ai, content: "첫 주장")],
      aiNotice: "AI의 주장이에요",
      replyMinLength: 50,
      replyMaxLength: 1000
    )
  }

  private func state() -> ClassAIChatFeature.State {
    let room = ClassRoom.mocks[0]
    return ClassAIChatFeature.State(
      room: room,
      battleID: room.battle.id,
      selectedOptionID: 1
    )
  }

  @Test
  func 저장된_토론이_없으면_서버에서_시작하고_응답을_표시한다() async throws {
    let response = debate(round: 2)
    let store = TestStore(initialState: state()) { ClassAIChatFeature() } withDependencies: {
      $0.classDebateUseCase = DebateStub(debate: response, hasExistingSession: false)
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let requestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .debateLoaded(requestID, .success(response)))

    #expect(store.state.debate == response)
    #expect(store.state.round == 2)
    #expect(store.state.messages.map(\.text) == ["첫 주장"])
    #expect(store.state.opponentName == "칸트")
  }

  @Test
  func 서버_반박_길이와_상태가_전송_가능_여부를_결정한다() {
    var state = state()
    state.apply(debate())
    state.draft = String(repeating: "가", count: 49)
    #expect(!state.canSend)
    state.draft += "가"
    #expect(state.canSend)
    state.draft = String(repeating: "가", count: 1000)
    #expect(state.canSend)
    state.draft += "가"
    #expect(!state.canSend)

    state.apply(debate(canReply: false))
    state.draft = String(repeating: "가", count: 50)
    #expect(!state.canSend)
  }

  @Test
  func 서버가_완료한_토론에서만_최종투표를_연다() async {
    let store = TestStore(initialState: state()) { ClassAIChatFeature() }
    await store.send(.view(.finalVoteTapped))

    let completed = debate(status: .completed, canReply: false, round: 3)
    var completedState = state()
    completedState.apply(completed)
    let completedStore = TestStore(initialState: completedState) { ClassAIChatFeature() }
    await completedStore.send(.view(.finalVoteTapped)) {
      $0.customAlert = .finalVote()
    }
  }

  @Test
  func 생성이_정체되어_재시도_가능하면_조회_대기를_끝낸다() async throws {
    let response = debate(status: .generating, canReply: false, canRetry: true)
    let store = TestStore(initialState: state()) { ClassAIChatFeature() } withDependencies: {
      $0.classDebateUseCase = DebateStub(debate: response)
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let requestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .debateLoaded(requestID, .success(response)))

    #expect(!store.state.isGenerating)
    #expect(store.state.canRetrySession)
  }

  @Test
  func 반박은_현재_라운드와_요청키로_서버에_제출하고_완료_응답을_따른다() async throws {
    let spy = DebateSpy()
    var initial = state()
    initial.apply(debate(round: 2))
    let completed = debate(status: .completed, canReply: false, round: 3)
    let store = TestStore(initialState: initial) { ClassAIChatFeature() } withDependencies: {
      $0.classDebateUseCase = DebateStub(debate: completed, spy: spy)
    }
    store.exhaustivity = .off
    let reply = String(repeating: "가", count: 50)

    await store.send(.view(.draftChanged(reply)))
    await store.send(.view(.sendTapped))
    let requestID = try #require(store.state.responseRequestID)
    let requestKey = try #require(store.state.replyRequestKey)
    await store.receive(\.inner, .replyLoaded(requestID, .success(completed)))

    let submission = await spy.submission
    #expect(submission == DebateSpy.Submission(round: 2, content: reply, requestKey: requestKey))
    #expect(store.state.isCompleted)
    #expect(!store.state.canSend)
  }
}

private actor DebateSpy {
  struct Submission: Equatable {
    let round: Int
    let content: String
    let requestKey: UUID
  }

  private(set) var submission: Submission?

  func record(round: Int, content: String, requestKey: UUID) {
    submission = .init(round: round, content: content, requestKey: requestKey)
  }
}
