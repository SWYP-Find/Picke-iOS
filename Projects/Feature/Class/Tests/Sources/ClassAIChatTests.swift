//
//  ClassAIChatTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

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

    func respond(_ text: String) throws -> String {
      if text.contains("토론을 시작") {
        return "처음부터 다시 생각해 보시겠어요?"
      }
      attempts += 1
      if attempts == 1 {
        throw ClassAIChatError.alreadyResponding
      }
      return "다른 관점도 생각해 볼까요?"
    }
  }

  private actor CallCounter {
    private var count = 0

    func record() {
      count += 1
    }

    func value() -> Int {
      count
    }
  }

  private actor EmptyThenSuccessStub {
    private var responseCount = 0

    func respond(_ text: String) -> String {
      if text.contains("토론을 시작") {
        return "첫 질문입니다."
      }
      responseCount += 1
      return responseCount == 1 ? " \n " : "두 번째 시도 답변입니다."
    }
  }

  private actor ReentryStartStub {
    private var starts = 0

    func start() throws {
      starts += 1
      if starts == 2 {
        throw ClassAIChatError.modelNotReady
      }
    }
  }

  private actor DelayedResponseStub {
    private var response: CheckedContinuation<String, Never>?
    private var started: CheckedContinuation<Void, Never>?

    func respond() async -> String {
      await withCheckedContinuation { continuation in
        response = continuation
        started?.resume()
        started = nil
      }
    }

    func waitUntilStarted() async {
      guard response == nil else { return }
      await withCheckedContinuation { started = $0 }
    }

    func complete() {
      response?.resume(returning: "늦은 성공 응답")
      response = nil
    }
  }

  private actor FinalRoundRecorder {
    private var flags: [Bool] = []

    func record(_ isFinalRound: Bool) {
      flags.append(isFinalRound)
    }

    func values() -> [Bool] {
      flags
    }
  }

  private actor StartStub {
    private var attempts = 0
    private let firstError: ClassAIChatError

    init(firstError: ClassAIChatError = .modelNotReady) {
      self.firstError = firstError
    }

    func start() throws {
      attempts += 1
      if attempts == 1 {
        throw firstError
      }
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
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, context in await recorder.record(context) },
        respond: { _, _, _ in "첫 질문입니다." }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let requestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(requestID, ["첫 질문입니다."]))

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
  func 실제_대화는_고정_답변_없이_모델의_첫_질문으로_시작한다() async throws {
    let store = TestStore(initialState: ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, _, _ in "당신이 택한 입장의 근거는 무엇인가요?" }
      )
    }
    store.exhaustivity = .off
    #expect(store.state.messages.isEmpty)
    await store.send(.view(.onAppear))
    let requestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(requestID, ["당신이 택한 입장의 근거는 무엇인가요?"]))
    #expect(store.state.messages.map(\.text) == ["당신이 택한 입장의 근거는 무엇인가요?"])
    #expect(store.state.round == 1)
  }

  @Test
  func 모델_준비_오류는_재시도로_복구한다() async throws {
    let stub = StartStub()
    let store = TestStore(initialState: ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in try await stub.start() },
        respond: { _, _, _ in "첫 질문입니다." }
      )
    }
    store.exhaustivity = .off
    await store.send(.view(.onAppear))
    let failedID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionFailed(failedID, .modelNotReady))
    #expect(store.state.canRetrySession)
    await store.send(.view(.retryTapped))
    let retryID = try #require(store.state.sessionRequestID)
    #expect(retryID != failedID)
    await store.receive(\.inner, .sessionReady(retryID, ["첫 질문입니다."]))
    #expect(!store.state.canRetrySession)
    #expect(store.state.messages.map(\.text) == ["첫 질문입니다."])
  }

  @Test
  func Apple_Intelligence를_켠_뒤_재시도할_수_있다() async throws {
    let stub = StartStub(firstError: .appleIntelligenceNotEnabled)
    let store = TestStore(initialState: ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in try await stub.start() },
        respond: { _, _, _ in "첫 질문입니다." }
      )
    }
    store.exhaustivity = .off
    await store.send(.view(.onAppear))
    let failedID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionFailed(failedID, .appleIntelligenceNotEnabled))
    #expect(store.state.canRetrySession)
  }

  @Test
  func 다시_나타난_화면은_첫_질문을_중복하지_않는다() async throws {
    let store = TestStore(initialState: ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, _, _ in "첫 질문입니다." }
      )
    }
    store.exhaustivity = .off
    await store.send(.view(.onAppear))
    let firstID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(firstID, ["첫 질문입니다."]))
    await store.send(.view(.onDisappear))
    await store.send(.view(.onAppear))
    let secondID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(secondID, []))
    #expect(store.state.messages.map(\.text) == ["첫 질문입니다."])
  }

  @Test
  func 이전_세션의_첫_응답은_대화에_추가하지_않는다() async {
    let staleID = UUID()
    var state = ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)
    state.sessionRequestID = UUID()
    let store = TestStore(initialState: state) { ClassAIChatFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.sessionReady(staleID, ["늦은 첫 질문"])))
    #expect(store.state.messages.isEmpty)
    #expect(store.state.round == 1)
  }

  @Test
  func 모델_응답을_최대_세_말풍선으로_나눈다() {
    #expect(ClassAIChatMessageUseCase.bubbles(from: "첫째. 둘째. 셋째. 넷째.") == [
      "첫째.", "둘째.", "셋째. 넷째.",
    ])
    #expect(ClassAIChatMessageUseCase.bubbles(from: " \n ").isEmpty)
  }

  @Test
  func 숫자와_연속_문장부호는_말풍선을_자르지_않는다() {
    #expect(ClassAIChatMessageUseCase.bubbles(from: "음... 그렇군요. 하지만 왜죠?") == [
      "음...", "그렇군요.", "하지만 왜죠?",
    ])
    #expect(ClassAIChatMessageUseCase.bubbles(from: "지지율이 3.5% 올랐어요. 그래도 부족해요.") == [
      "지지율이 3.5% 올랐어요.", "그래도 부족해요.",
    ])
    #expect(ClassAIChatMessageUseCase.bubbles(from: "정말요?! 저는 반대예요.") == [
      "정말요?!", "저는 반대예요.",
    ])
  }

  @Test
  func 너무_긴_응답은_문장_경계에서_자른다() {
    let first = String(repeating: "가", count: 200) + "."
    let second = String(repeating: "나", count: 150) + "."
    #expect(ClassAIChatMessageUseCase.bubbles(from: first + " " + second) == [first])
  }

  @Test
  func 한_문장이_길어도_중간에서_자르지_않는다() {
    let sentence = String(repeating: "가", count: 350) + "."
    #expect(ClassAIChatMessageUseCase.bubbles(from: sentence) == [sentence])
  }

  @Test
  func 합친_말풍선도_공백을_포함해_길이_한도를_지킨다() {
    let response = Array(repeating: "반대.", count: 100).joined(separator: " ")
    let bubbles = ClassAIChatMessageUseCase.bubbles(from: response)

    #expect(bubbles.count == 3)
    #expect(bubbles.joined(separator: " ").count <= 300)
    #expect(bubbles.allSatisfy { $0.hasSuffix(".") })
  }

  @Test
  func 마지막_라운드_응답만_마무리_요청으로_보낸다() async throws {
    let recorder = FinalRoundRecorder()
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: aiRoom,
      battleID: -1,
      selectedOptionID: 1
    )) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, _, isFinalRound in
          await recorder.record(isFinalRound)
          return "답변입니다."
        },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let sessionRequestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(sessionRequestID, ["답변입니다."]))
    for _ in 1 ... 3 {
      await store.send(.view(.draftChanged("제 생각")))
      await store.send(.view(.sendTapped))
      let responseRequestID = try #require(store.state.responseRequestID)
      await store.receive(\.inner, .responseReceived(responseRequestID, ["답변입니다."]))
    }

    #expect(await recorder.values() == [false, false, false, true])
  }

  @Test
  func 안내_문구는_상대_이름에_맞는_조사를_붙인다() {
    let room = aiRoom
    let platoSide = ClassAIChatFeature.State(room: room, battleID: -1, selectedOptionID: 1)
    let sartreSide = ClassAIChatFeature.State(room: room, battleID: -1, selectedOptionID: 2)

    #expect(platoSide.stanceNoticeSegments.map(\.text).joined().contains("반대 입장의 플라톤과 3라운드"))
    #expect(sartreSide.stanceNoticeSegments.map(\.text).joined().contains("반대 입장의 사르트르와 3라운드"))
    #expect(sartreSide.thinkingText == "사르트르가 답변을 생각하고 있어요")
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
        respond: { _, _, _ in "첫 답변. 두 번째 답변." },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let sessionRequestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(sessionRequestID, ["첫 답변.", "두 번째 답변."]))
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
        respond: { _, text, _ in try await stub.respond(text) },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let sessionRequestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(sessionRequestID, ["처음부터 다시 생각해 보시겠어요?"]))
    await store.send(.view(.draftChanged("제 생각")))
    await store.send(.view(.sendTapped))
    let failedRequestID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseFailed(failedRequestID, .alreadyResponding))
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
    initialState.messages.append(.init(speaker: .opponent, text: "선택한 입장의 근거는 무엇인가요?"))
    initialState.messages.append(.init(speaker: .user, text: "취소된 문장"))
    let store = TestStore(initialState: initialState) {
      ClassAIChatFeature()
    } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(start: { _, _ in }, respond: { _, _, _ in "" }, end: { _ in })
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

  @Test
  func 취소를_무시한_의존성이_늦게_성공해도_응답_액션을_보내지_않는다() async throws {
    let delayed = DelayedResponseStub()
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: aiRoom,
      battleID: -1,
      selectedOptionID: 1
    )) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, text, _ in
          if text.contains("토론을 시작") {
            return "첫 질문입니다."
          }
          return await delayed.respond()
        },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let openingID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(openingID, ["첫 질문입니다."]))
    await store.send(.view(.draftChanged("제 생각")))
    await store.send(.view(.sendTapped))
    await delayed.waitUntilStarted()
    await store.send(.view(.onDisappear))
    await delayed.complete()
    await store.finish(timeout: .seconds(1))

    #expect(store.state.messages.map(\.text) == ["첫 질문입니다."])
    #expect(store.state.draft == "제 생각")
    #expect(store.state.round == 1)
  }

  @Test
  func 재진입은_완료된_대화만_전달하고_첫_질문을_반복하지_않는다() async throws {
    let recorder = ContextRecorder()
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: aiRoom,
      battleID: -1,
      selectedOptionID: 1
    )) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, context in await recorder.record(context) },
        respond: { _, text, _ in
          text.contains("토론을 시작") ? "첫 질문입니다." : "첫 답변입니다."
        },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let openingID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(openingID, ["첫 질문입니다."]))
    await store.send(.view(.draftChanged("제 주장입니다")))
    await store.send(.view(.sendTapped))
    let responseID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseReceived(responseID, ["첫 답변입니다."]))
    let completed = store.state.messages
    await store.send(.view(.onDisappear))
    await store.send(.view(.onAppear))
    let reentryID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(reentryID, []))

    #expect(await recorder.value()?.priorMessages == completed)
    #expect(store.state.messages == completed)
    #expect(store.state.round == 2)
  }

  @Test
  func 거절된_입력은_같은_초안으로_다시_보내지_못하고_재진입에도_유지된다() async throws {
    let recorder = ContextRecorder()
    let calls = CallCounter()
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: aiRoom,
      battleID: -1,
      selectedOptionID: 1
    )) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, context in await recorder.record(context) },
        respond: { _, text, _ in
          await calls.record()
          if text.contains("토론을 시작") {
            return "첫 질문입니다."
          }
          throw ClassAIChatError.contentRejected
        },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let openingID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(openingID, ["첫 질문입니다."]))
    await store.send(.view(.draftChanged("거절된 입력")))
    await store.send(.view(.sendTapped))
    let responseID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseFailed(responseID, .contentRejected))
    #expect(await calls.value() == 2)
    #expect(store.state.draft == "거절된 입력")
    #expect(store.state.round == 1)
    #expect(!store.state.canSend)
    #expect(store.state.errorMessage == ClassAIChatError.contentRejected.localizedDescription)
    await store.send(.view(.draftChanged("거절된 입력")))
    await store.send(.view(.sendTapped))
    #expect(await calls.value() == 2)
    #expect(!store.state.canSend)
    #expect(store.state.errorMessage != nil)
    await store.send(.view(.onDisappear))
    await store.send(.view(.onAppear))
    let reentryID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(reentryID, []))
    #expect(await calls.value() == 2)
    #expect(await recorder.value()?.priorMessages.map(\.text) == ["첫 질문입니다."])
    #expect(store.state.errorMessage != nil)
    #expect(!store.state.canSend)
    await store.send(.view(.draftChanged("수정한 입력")))
    #expect(store.state.canSend)
    #expect(store.state.errorMessage == nil)
  }

  @Test
  func 거절_후_재진입_준비가_한번_실패해도_재시도_성공시_거절_문구를_복구한다() async throws {
    let starts = ReentryStartStub()
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: aiRoom,
      battleID: -1,
      selectedOptionID: 1
    )) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in try await starts.start() },
        respond: { _, text, _ in
          if text.contains("토론을 시작") {
            return "첫 질문입니다."
          }
          throw ClassAIChatError.contentRejected
        },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let openingID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(openingID, ["첫 질문입니다."]))
    await store.send(.view(.draftChanged("거절된 입력")))
    await store.send(.view(.sendTapped))
    let blockedID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseFailed(blockedID, .contentRejected))
    await store.send(.view(.onDisappear))
    await store.send(.view(.onAppear))
    let failedReentryID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionFailed(failedReentryID, .modelNotReady))
    #expect(store.state.canRetrySession)
    #expect(store.state.errorMessage == ClassAIChatError.modelNotReady.localizedDescription)
    await store.send(.view(.retryTapped))
    let retryID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(retryID, []))
    #expect(store.state.errorMessage == ClassAIChatError.contentRejected.localizedDescription)
    #expect(store.state.draft == "거절된 입력")
    #expect(!store.state.canSend)
  }

  @Test
  func 첫_질문_거절은_재진입해도_자동_재시도하지_않는다() async throws {
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: aiRoom,
      battleID: -1,
      selectedOptionID: 1
    )) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in throw ClassAIChatError.contentRejected },
        respond: { _, _, _ in "" },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let requestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionFailed(requestID, .contentRejected))
    #expect(store.state.isTerminal)
    #expect(!store.state.canRetrySession)
    #expect(store.state.errorMessage?.contains("첫 질문") == true)
    #expect(store.state.errorMessage?.contains("최종투표") == true)
    await store.send(.view(.onDisappear))
    await store.send(.view(.onAppear))
    #expect(store.state.sessionRequestID == nil)
    #expect(store.state.isTerminal)
  }

  @Test
  func 긴_입력은_초안과_라운드를_보존하고_모델에_전송하지_않는다() async {
    var state = ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)
    state.hasStarted = true
    state.messages = [.init(speaker: .opponent, text: "첫 질문입니다.")]
    state.draft = String(repeating: "가", count: 241)
    let store = TestStore(initialState: state) { ClassAIChatFeature() }

    await store.send(.view(.sendTapped)) {
      $0.errorMessage = "240자 이내로 줄여 주세요."
    }
    #expect(store.state.draft.count == 241)
    #expect(store.state.messages.count == 1)
    #expect(store.state.round == 1)
    #expect(store.state.responseRequestID == nil)
  }

  @Test
  func 빈_응답은_초안을_복구하고_명시적인_재전송만_허용한다() async throws {
    let stub = EmptyThenSuccessStub()
    let store = TestStore(initialState: ClassAIChatFeature.State(
      room: aiRoom,
      battleID: -1,
      selectedOptionID: 1
    )) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, text, _ in await stub.respond(text) }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let openingID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(openingID, ["첫 질문입니다."]))
    await store.send(.view(.draftChanged("제 생각")))
    await store.send(.view(.sendTapped))
    let responseID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseFailed(responseID, .emptyResponse))
    #expect(store.state.draft == "제 생각")
    #expect(store.state.round == 1)
    #expect(store.state.canSend)
    #expect(store.state.messages.map(\.text) == ["첫 질문입니다."])
    await store.send(.view(.sendTapped))
    let retryID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseReceived(retryID, ["두 번째 시도 답변입니다."]))
    #expect(store.state.round == 2)
    #expect(store.state.draft.isEmpty)
  }

  @Test
  func 응답_모델_준비_오류는_자동_재호출_없이_사용자_재전송으로_복구한다() async throws {
    let requestID = UUID()
    let calls = CallCounter()
    var state = ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)
    state.hasStarted = true
    state.isGenerating = true
    state.responseRequestID = requestID
    state.pendingText = "제 주장"
    state.messages = [
      .init(speaker: .opponent, text: "첫 질문"),
      .init(speaker: .user, text: "제 주장"),
    ]
    let store = TestStore(initialState: state) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, _, _ in
          await calls.record()
          return "복구한 답변"
        }
      )
    }
    store.exhaustivity = .off

    await store.send(.inner(.responseFailed(requestID, .modelNotReady)))
    #expect(await calls.value() == 0)
    #expect(store.state.canSend)
    #expect(store.state.draft == "제 주장")
    await store.send(.view(.sendTapped))
    let retryID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseReceived(retryID, ["복구한 답변"]))
    #expect(await calls.value() == 1)
    #expect(store.state.round == 2)
  }

  @Test
  func 응답_한국어_미지원은_토론을_종료하고_최종투표를_안내한다() async {
    let requestID = UUID()
    var state = ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)
    state.hasStarted = true
    state.isGenerating = true
    state.responseRequestID = requestID
    state.pendingText = "제 주장"
    state.messages = [
      .init(speaker: .opponent, text: "첫 질문"),
      .init(speaker: .user, text: "제 주장"),
    ]
    let store = TestStore(initialState: state) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(start: { _, _ in }, respond: { _, _, _ in "" }, end: { _ in })
    }
    store.exhaustivity = .off

    await store.send(.inner(.responseFailed(requestID, .unsupportedLanguage)))
    #expect(store.state.isTerminal)
    #expect(!store.state.isModelAvailable)
    #expect(store.state.errorMessage?.contains("최종투표") == true)
    await store.send(.view(.onDisappear))
    await store.send(.view(.onAppear))
    #expect(store.state.sessionRequestID == nil)
  }

  @Test
  func 재진입_후_세번째_라운드만_마무리_신호를_전달한다() async throws {
    let flags = FinalRoundRecorder()
    var state = ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)
    state.round = 3
    state.messages = [
      .init(speaker: .opponent, text: "첫 질문"),
      .init(speaker: .user, text: "첫 주장"),
      .init(speaker: .opponent, text: "두번째 답변"),
    ]
    let store = TestStore(initialState: state) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in },
        respond: { _, _, isFinalRound in
          await flags.record(isFinalRound)
          return "마지막 답변"
        },
        end: { _ in }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let reentryID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionReady(reentryID, []))
    await store.send(.view(.draftChanged("마지막 주장")))
    await store.send(.view(.sendTapped))
    let responseID = try #require(store.state.responseRequestID)
    await store.receive(\.inner, .responseReceived(responseID, ["마지막 답변"]))
    #expect(await flags.values() == [true])
    #expect(store.state.isCompleted)
  }

  @Test
  func 재진입_세션의_종료_오류는_첫_질문_오류로_표시하지_않는다() async throws {
    var state = ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)
    state.messages = [.init(speaker: .opponent, text: "이미 받은 첫 질문")]
    let store = TestStore(initialState: state) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(
        start: { _, _ in throw ClassAIChatError.unsupportedLanguage },
        respond: { _, _, _ in "" }
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    let requestID = try #require(store.state.sessionRequestID)
    await store.receive(\.inner, .sessionFailed(requestID, .unsupportedLanguage))
    #expect(store.state.isTerminal)
    #expect(store.state.errorMessage == ClassAIChatError.unsupportedLanguage.localizedDescription)
    #expect(store.state.messages.map(\.text) == ["이미 받은 첫 질문"])
  }

  @Test
  func 문맥_초과는_최종투표_안내를_남기고_재진입을_막는다() async {
    var state = ClassAIChatFeature.State(room: aiRoom, battleID: -1, selectedOptionID: 1)
    let requestID = UUID()
    state.hasStarted = true
    state.isGenerating = true
    state.responseRequestID = requestID
    state.pendingText = "제 주장"
    state.messages = [
      .init(speaker: .opponent, text: "첫 질문"),
      .init(speaker: .user, text: "제 주장"),
    ]
    let store = TestStore(initialState: state) { ClassAIChatFeature() } withDependencies: {
      $0.classAIChatUseCase = MockClassAIChatUseCase(start: { _, _ in }, respond: { _, _, _ in "" }, end: { _ in })
    }
    store.exhaustivity = .off

    await store.send(.inner(.responseFailed(requestID, .contextExhausted)))
    #expect(store.state.draft == "제 주장")
    #expect(store.state.isTerminal)
    #expect(!store.state.isModelAvailable)
    #expect(store.state.errorMessage?.contains("최종투표") == true)
    await store.send(.view(.draftChanged("제 주장")))
    #expect(store.state.errorMessage?.contains("최종투표") == true)
    await store.send(.view(.onDisappear))
    await store.send(.view(.onAppear))
    #expect(store.state.sessionRequestID == nil)
  }
}
