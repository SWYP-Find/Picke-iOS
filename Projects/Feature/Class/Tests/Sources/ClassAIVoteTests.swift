//
//  ClassAIVoteTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

import BattleDomainInterface
@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassAIVoteTests {
  private let instanceID = UUID(0)
  private let requestID = UUID(1)
  private let battleID = -1_000_001

  private func initialState() -> ClassAIVoteFeature.State {
    ClassAIVoteFeature.State(
      room: ClassRoom.mocks[0],
      battleID: battleID,
      instanceID: instanceID
    )
  }

  @Test
  func 처음에는_로딩이며_조회_전에는_선택과_제출을_막는다() async {
    var state = initialState()
    state.selectedOptionID = 1
    #expect(state.viewState == .loading)
    #expect(!state.canSubmit)
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    await store.send(.view(.optionTapped(2)))
    await store.send(.view(.submitTapped))
  }

  @Test
  func 첫_조회_성공_후_다시_나타나도_조회하지_않는다() async {
    let store = TestStore(initialState: initialState()) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.battleUseCase = MockBattleRepository()
    }
    await store.send(.view(.onAppear)) {
      $0.loadRequestID = requestID
    }
    await store.receive(\.inner, .voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .success(.init(status: .none, step: .none))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
    }
    #expect(store.state.viewState == .loaded)
    await store.send(.view(.onAppear))
    await store.send(.view(.optionTapped(1))) { $0.selectedOptionID = 1 }
    #expect(store.state.canSubmit)
  }

  @Test
  func 조회중_중복_등장과_재시도는_요청을_추가하지_않는다() async {
    var state = initialState()
    state.loadRequestID = requestID
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    await store.send(.view(.onAppear))
    await store.send(.view(.retryTapped))
  }

  @Test
  func 조회_실패_후_재시도하면_투표를_선택할_수_있다() async {
    var state = initialState()
    state.loadRequestID = requestID
    let retryID = UUID(2)
    let store = TestStore(initialState: state) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(retryID)
      $0.battleUseCase = MockBattleRepository()
    }
    await store.send(.inner(.voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .failure(.noData)
    ))) {
      $0.loadRequestID = nil
      $0.viewState = .error
      $0.errorMessage = "투표 상태를 불러오지 못했어요. 다시 시도해 주세요."
    }
    #expect(store.state.viewState == .error)
    await store.send(.view(.optionTapped(1)))
    await store.send(.view(.retryTapped)) {
      $0.loadRequestID = retryID
      $0.viewState = .loading
      $0.errorMessage = nil
    }
    await store.receive(\.inner, .voteLoaded(
      instanceID: instanceID,
      requestID: retryID,
      battleID: battleID,
      .success(.init(status: .none, step: .none))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
    }
  }

  @Test
  func 이전_화면과_요청과_배틀의_응답은_무시한다() async {
    var state = initialState()
    state.loadRequestID = requestID
    state.submitRequestID = requestID
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    for identity in [
      (UUID(2), requestID, battleID),
      (instanceID, UUID(2), battleID),
      (instanceID, requestID, battleID - 1),
    ] {
      await store.send(.inner(.voteLoaded(
        instanceID: identity.0,
        requestID: identity.1,
        battleID: identity.2,
        .success(.init(status: .pro, step: .completed))
      )))
      await store.send(.inner(.voteSubmitted(
        instanceID: identity.0,
        requestID: identity.1,
        battleID: identity.2,
        .success(.init(voteId: 1, status: .created))
      )))
    }
  }

  @Test
  func 뒤로가기_후_늦은_응답은_화면을_변경하지_않는다() async {
    var state = initialState()
    state.loadRequestID = requestID
    state.submitRequestID = requestID
    state.isSubmitting = true
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    await store.send(.view(.backTapped)) {
      $0.loadRequestID = nil
      $0.submitRequestID = nil
      $0.isSubmitting = false
    }
    await store.receive(\.delegate, .dismiss)
    await store.send(.inner(.voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .failure(.noData)
    )))
    await store.send(.inner(.voteSubmitted(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .success(.init(voteId: 1, status: .created))
    )))
  }

  @Test
  func 조회된_새_투표는_저장_성공_후에만_이동을_알린다() async {
    var state = initialState()
    state.viewState = .loaded
    state.selectedOptionID = 2
    let store = TestStore(initialState: state) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.battleUseCase = MockBattleRepository()
    }
    await store.send(.view(.submitTapped)) {
      $0.isSubmitting = true
      $0.submitRequestID = requestID
    }
    await store.receive(\.inner, .voteSubmitted(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .success(.init(voteId: 0, status: .none))
    )) {
      $0.submitRequestID = nil
      $0.isSubmitting = false
      $0.hasSubmitted = true
      $0.submittedOptionID = 2
    }
    await store.receive(\.delegate, .voteSubmitted(
      battleID: battleID,
      selectedOptionID: 2,
      hasCompletedPostVote: false
    ))
  }

  @Test(arguments: [false, true])
  func 기존_투표자는_사후투표_완료_여부에_맞춰_진입한다(completed: Bool) async {
    var state = initialState()
    state.loadRequestID = requestID
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    await store.send(.inner(.voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .success(.init(status: completed ? .pro : .con, step: completed ? .completed : .listening))
    ))) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
      $0.selectedOptionID = completed ? 1 : 2
      $0.submittedOptionID = completed ? 1 : 2
      $0.hasSubmitted = true
      $0.hasCompletedPostVote = completed
    }
    await store.send(.view(.submitTapped))
    await store.receive(\.delegate, .voteSubmitted(
      battleID: battleID,
      selectedOptionID: completed ? 1 : 2,
      hasCompletedPostVote: completed
    ))
  }

  @Test
  func 실제_클래스_사전투표는_서버_선택지_ID로_제출한다() async {
    let spy = ClassVoteSpy()
    let store = TestStore(initialState: .init(
      room: ClassRoom.mocks[0],
      battleID: 99,
      instanceID: instanceID,
      isLiveClassBattle: true
    )) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassVoteUseCaseStub(spy: spy)
    }
    await store.send(.view(.onAppear)) { $0.loadRequestID = requestID }
    await store.receive(\.inner, .voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: 99,
      .success(.init(
        status: .none,
        step: .none,
        optionIDs: [17, 29],
        options: ClassVoteUseCaseStub.options
      ))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
      $0.classOptionIDs = [17, 29]
      $0.classOptions = ClassVoteUseCaseStub.options
      $0.canChangePreVote = true
    }
    #expect(store.state.optionATitle == "찬성")
    #expect(store.state.optionBTitle == "반대")
    await store.send(.view(.optionTapped(2))) { $0.selectedOptionID = 2 }
    await store.send(.view(.submitTapped)) {
      $0.isSubmitting = true
      $0.submitRequestID = requestID
    }
    await store.receive(\.inner, .voteSubmitted(
      instanceID: instanceID,
      requestID: requestID,
      battleID: 99,
      .success(.init(voteId: 5, status: .created))
    )) {
      $0.submitRequestID = nil
      $0.isSubmitting = false
      $0.hasSubmitted = true
      $0.submittedOptionID = 2
    }
    await store.receive(\.delegate, .voteSubmitted(
      battleID: 99,
      selectedOptionID: 2,
      hasCompletedPostVote: false
    ))
    let submissions = await spy.submitted
    #expect(submissions == [.pre(29)])
  }

  @Test
  func 실제_AI_사후투표는_클래스_사후투표_API를_호출한다() async {
    let spy = ClassVoteSpy()
    var state = ClassAIVoteFeature.State(
      room: ClassRoom.mocks[0],
      battleID: 99,
      instanceID: instanceID,
      isLiveClassBattle: true,
      isPostVote: true
    )
    state.viewState = .loaded
    state.classOptionIDs = [17, 29]
    state.selectedOptionID = 1
    let store = TestStore(initialState: state) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassVoteUseCaseStub(spy: spy)
    }
    await store.send(.view(.submitTapped)) {
      $0.isSubmitting = true
      $0.submitRequestID = requestID
    }
    await store.receive(\.inner, .voteSubmitted(
      instanceID: instanceID,
      requestID: requestID,
      battleID: 99,
      .success(.init(voteId: 6, status: .created))
    )) {
      $0.submitRequestID = nil
      $0.isSubmitting = false
      $0.hasSubmitted = true
      $0.submittedOptionID = 1
      $0.hasCompletedPostVote = true
    }
    await store.receive(\.delegate, .voteSubmitted(
      battleID: 99,
      selectedOptionID: 1,
      hasCompletedPostVote: true
    ))
    let submissions = await spy.submitted
    #expect(submissions == [.post(17)])
  }

  @Test(arguments: [ClassBattleStep.none, .preVote])
  func 배틀_시작_전에는_기존_사전투표를_다시_제출할_수_있다(step: ClassBattleStep) async {
    let spy = ClassVoteSpy()
    var state = ClassAIVoteFeature.State(
      room: ClassRoom.mocks[0],
      battleID: 99,
      instanceID: instanceID,
      isLiveClassBattle: true
    )
    state.loadRequestID = requestID
    let store = TestStore(initialState: state) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassVoteUseCaseStub(spy: spy)
    }
    let progressStep: BattleStep = step == .none ? .none : .preVote
    await store.send(.inner(.voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: 99,
      .success(.init(
        status: .pro,
        step: progressStep,
        optionIDs: [17, 29],
        options: ClassVoteUseCaseStub.options
      ))
    ))) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
      $0.classOptionIDs = [17, 29]
      $0.classOptions = ClassVoteUseCaseStub.options
      $0.selectedOptionID = 1
      $0.submittedOptionID = 1
      $0.canChangePreVote = true
      $0.hasSubmitted = true
    }
    await store.send(.view(.submitTapped))
    await store.receive(\.delegate, .voteSubmitted(
      battleID: 99,
      selectedOptionID: 1,
      hasCompletedPostVote: false
    ))
    await store.send(.view(.optionTapped(2))) { $0.selectedOptionID = 2 }
    #expect(store.state.submitTitle == "투표 수정하기")
    await store.send(.view(.submitTapped)) {
      $0.isSubmitting = true
      $0.submitRequestID = requestID
    }
    await store.receive(\.inner, .voteSubmitted(
      instanceID: instanceID,
      requestID: requestID,
      battleID: 99,
      .success(.init(voteId: 5, status: .created))
    )) {
      $0.submitRequestID = nil
      $0.isSubmitting = false
      $0.submittedOptionID = 2
    }
    await store.receive(\.delegate, .voteSubmitted(
      battleID: 99,
      selectedOptionID: 2,
      hasCompletedPostVote: false
    ))
    #expect(store.state.submitTitle == "의견 보기")
    let submissions = await spy.submitted
    #expect(submissions == [.pre(29)])
  }

  @Test
  func 서버가_토론_시작을_알리면_과거_투표_상태가_PRE_VOTE여도_변경을_막는다() async {
    let spy = ClassVoteSpy()
    let history = ClassVoteHistory(
      battleTitle: "투표 테스트",
      preVote: .init(optionID: 17, label: "A", title: "찬성"),
      postVote: nil,
      status: .preVote,
      opinionChanged: nil
    )
    let store = TestStore(initialState: .init(
      room: ClassRoom.mocks[0],
      battleID: 99,
      instanceID: instanceID,
      isLiveClassBattle: true
    )) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassVoteUseCaseStub(
        spy: spy,
        step: .ttsListening,
        history: history
      )
    }
    await store.send(.view(.onAppear)) { $0.loadRequestID = requestID }
    await store.receive(\.inner, .voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: 99,
      .success(.init(
        status: .pro,
        step: .listening,
        optionIDs: [17, 29],
        options: ClassVoteUseCaseStub.options
      ))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
      $0.classOptionIDs = [17, 29]
      $0.classOptions = ClassVoteUseCaseStub.options
      $0.selectedOptionID = 1
      $0.submittedOptionID = 1
      $0.hasSubmitted = true
    }
    await store.send(.view(.optionTapped(2)))
    await store.send(.view(.submitTapped))
    await store.receive(\.delegate, .voteSubmitted(
      battleID: 99,
      selectedOptionID: 1,
      hasCompletedPostVote: false
    ))
    let submissions = await spy.submitted
    #expect(submissions.isEmpty)
  }
}

private actor ClassVoteSpy {
  enum Submission: Equatable {
    case pre(Int), post(Int)
  }

  private(set) var submitted: [Submission] = []

  func record(_ submission: Submission) {
    submitted.append(submission)
  }
}

private struct ClassVoteUseCaseStub: ClassBattleInterface {
  let spy: ClassVoteSpy
  var step: ClassBattleStep = .none
  var history: ClassVoteHistory? = nil
  static let options: [ClassBattleOption] = [
    .init(id: 17, label: "A", title: "찬성", stance: "찬성 근거", representative: "", imageURL: nil),
    .init(id: 29, label: "B", title: "반대", stance: "반대 근거", representative: "", imageURL: nil),
  ]

  func fetchBattle(classID: Int) async throws -> ClassBattleSession {
    ClassBattleSession(
      classID: classID,
      myRole: .member,
      closeAt: .distantFuture,
      closed: false,
      commentRequired: false,
      canParticipate: true,
      participationCompleted: false,
      battle: .init(
        id: 99,
        title: "투표 테스트",
        summary: "",
        thumbnailURL: nil,
        description: "",
        shareURL: nil,
        userVoteStatus: nil,
        currentStep: step,
        participantsCount: 0,
        audioDuration: 0,
        options: Array(Self.options.reversed())
      )
    )
  }

  func submitPreVote(classID _: Int, optionID: Int) async throws -> ClassVoteReceipt {
    await spy.record(.pre(optionID))
    return .init(voteID: 5, status: .preVote)
  }

  func completeTTS(classID _: Int) async throws {
    throw ClassBattleError.invalidResponse
  }

  func submitPostVote(classID _: Int, optionID: Int) async throws -> ClassVoteReceipt {
    await spy.record(.post(optionID))
    return .init(voteID: 6, status: .completed)
  }

  func fetchMyVotes(classID _: Int) async throws -> ClassVoteHistory {
    guard let history else { throw ClassBattleError.voteNotFound }
    return history
  }

  func fetchVoteStats(classID _: Int) async throws -> ClassVoteStats {
    throw ClassBattleError.invalidResponse
  }

  func publishPerspective(classID _: Int, content _: String) async throws -> ClassPerspectiveReceipt {
    throw ClassBattleError.invalidResponse
  }

  func fetchPerspectives(
    classID _: Int,
    cursor _: String?,
    size _: Int?,
    optionID _: Int?,
    sort _: String?
  ) async throws -> ClassPerspectivePage {
    throw ClassBattleError.invalidResponse
  }

  func fetchMyPerspectives(classID _: Int) async throws -> [ClassPerspectiveItem] {
    throw ClassBattleError.invalidResponse
  }
}
