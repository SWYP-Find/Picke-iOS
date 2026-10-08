@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassAIChatTests {
  private actor ContextRecorder {
    private var captured: ClassAIChatContext?

    func record(_ context: ClassAIChatContext) {
      captured = context
    }

    func value() -> ClassAIChatContext? {
      captured
    }
  }

  private actor ResponseStub {
    private var attempts = 0

    func respond() throws -> String {
      attempts += 1
      if attempts == 1 {
        throw ClassAIChatError.alreadyResponding
      }
      return "다른 관점도 생각해 볼까요?"
    }
  }

  private var aiRoom: ClassRoom {
    let room = ClassRoom.mocks[0]
    return .init(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: ClassSettingFeature.State(aiQuestion: ClassAIQuestion.examples[0], filter: .init()).aiBattle!,
      deadline: room.deadline,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment
    )
  }

  private func room(for question: ClassAIQuestion) -> ClassRoom {
    let room = ClassRoom.mocks[0]
    return .init(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: ClassSettingFeature.State(aiQuestion: question, filter: .init()).aiBattle!,
      deadline: room.deadline,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment
    )
  }

  private func assertForwardedContext(
    question: ClassAIQuestion,
    selectedOptionID: Int,
    expectedPhilosopherName: String?
  ) async throws {
    let room = room(for: question)
    let recorder = ContextRecorder()
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: room,
      battleID: room.battle.id,
      selectedOptionID: selectedOptionID
    )) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(start: { _, context in
        await recorder.record(context)
      })
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let requestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(requestID))

    let context = try #require(await recorder.value())
    #expect(context.question == room.battle.title)
    #expect(context.selectedStance == (selectedOptionID == 1 ? room.battle.optionATitle : room.battle.optionBTitle))
    #expect(context.opponentStance == (selectedOptionID == 1 ? room.battle.optionBTitle : room.battle.optionATitle))
    #expect(context.opponentPhilosopherName == expectedPhilosopherName)
  }

  @Test
  func 이름있는_AI_질문의_양쪽_선택지를_원본대로_전달한다() async throws {
    let question = ClassAIQuestion.examples[0]
    try await assertForwardedContext(question: question, selectedOptionID: 1, expectedPhilosopherName: "플라톤")
    try await assertForwardedContext(question: question, selectedOptionID: 2, expectedPhilosopherName: "사르트르")
  }

  @Test
  func 이름없는_AI_질문의_양쪽_선택지는_철학자_이름없이_전달한다() async throws {
    let question = ClassAIQuestion.examples[1]
    try await assertForwardedContext(question: question, selectedOptionID: 1, expectedPhilosopherName: nil)
    try await assertForwardedContext(question: question, selectedOptionID: 2, expectedPhilosopherName: nil)
  }

  @Test
  func 선택한_입장의_반대_철학자를_표시한다() {
    let room = aiRoom
    let selectedA = ClassAIChatFeature.State(room: room, battleID: -1_000_001, selectedOptionID: 1)
    let selectedB = ClassAIChatFeature.State(room: room, battleID: -1_000_001, selectedOptionID: 2)

    #expect(selectedA.selectedStanceTitle == room.battle.optionATitle)
    #expect(selectedA.opponentName == "플라톤")
    #expect(selectedB.selectedStanceTitle == room.battle.optionBTitle)
    #expect(selectedB.opponentName == "사르트르")
  }

  @Test
  func 모델_응답을_최대_세_말풍선으로_나눈다() {
    #expect(ClassAIChatMessageUseCase.bubbles(from: "첫째. 둘째. 셋째. 넷째.") == [
      "첫째.", "둘째.", "셋째. 넷째.",
    ])
    #expect(ClassAIChatMessageUseCase.bubbles(from: " \n ").isEmpty)
  }

  @Test
  func 세_번의_성공_응답_뒤에만_최종투표를_연다() async throws {
    let room = aiRoom
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: room,
      battleID: -1_000_001,
      selectedOptionID: 1
    )) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, _ in "첫 답변. 두 번째 답변." },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let sessionRequestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(sessionRequestID))
    for expectedRound in 1 ... 3 {
      await store.send(.view(.draftChanged("제 생각")))
      await store.send(.view(.sendTapped))
      let responseRequestID = try #require(store.state.responseRequestID)
      await store.receive(\.inner, .responseReceived(responseRequestID, ["첫 답변.", "두 번째 답변."]))
      #expect(store.state.isCompleted == (expectedRound == 3))
    }
    #expect(store.state.customAlert?.title == "최종투표하고 투표 결과를 보시겠습니까?")
    let count = store.state.messages.count
    await store.send(.view(.sendTapped))
    #expect(store.state.messages.count == count)
    await store.send(.customAlert(.presented(.cancelTapped)))
    #expect(store.state.customAlert == nil)
    await store.send(.view(.finalVoteTapped))
    #expect(store.state.customAlert != nil)
  }

  @Test
  func 생성_실패_뒤_입력문을_복구하고_재시도할_수_있다() async throws {
    let stub = ResponseStub()
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: aiRoom,
      battleID: -1_000_001,
      selectedOptionID: 1
    )) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, _ in try await stub.respond() },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let sessionRequestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(sessionRequestID))
    await store.send(.view(.draftChanged("제 생각")))
    await store.send(.view(.sendTapped))
    let failedRequestID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseFailed(
      failedRequestID,
      ClassAIChatError.alreadyResponding.localizedDescription
    ))
    #expect(store.state.draft == "제 생각")
    #expect(store.state.round == 1)
    #expect(store.state.errorMessage != nil)
    #expect(!store.state.isGenerating)
    #expect(store.state.messages.last?.speaker == .opponent)

    await store.send(.view(.sendTapped))
    let retriedRequestID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseReceived(
      retriedRequestID,
      ["다른 관점도 생각해 볼까요?"]
    ))
    #expect(store.state.round == 2)
    #expect(store.state.errorMessage == nil)
    #expect(store.state.draft.isEmpty)
  }

  @Test
  func 화면을_떠난_뒤_늦은_응답은_무시한다() async {
    let staleID = UUID()
    var initialState = ClassAIChatFeature.State(room: aiRoom, battleID: -1_000_001, selectedOptionID: 1)
    let previousConversationID = initialState.conversationID
    initialState.hasStarted = true
    initialState.isGenerating = true
    initialState.responseRequestID = staleID
    initialState.pendingText = "취소된 문장"
    initialState.messages.append(.init(speaker: .user, text: "취소된 문장"))
    let store = TestStore(initialState: initialState) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(start: { _, _ in }, respond: { _, _ in "" }, end: { _ in })
    }
    store.exhaustivity = .off

    await store.send(.view(.onDisappear))
    #expect(!store.state.isGenerating)
    #expect(store.state.draft == "취소된 문장")
    #expect(store.state.pendingText == nil)
    #expect(store.state.messages.last?.speaker == .opponent)
    #expect(store.state.conversationID != previousConversationID)
    await store.send(.inner(.responseReceived(staleID, ["늦은 답변"])))
    #expect(store.state.messages.last?.text != "늦은 답변")
    #expect(store.state.round == 1)
  }
}
