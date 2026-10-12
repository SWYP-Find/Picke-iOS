//
//  ClassReportTests.swift
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
struct ClassReportTests {
  @Test
  func 결과_탭을_선택하면_해당_내용으로_바뀐다() async {
    let store = TestStore(initialState: ClassReportFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())) {
      ClassReportFeature()
    }

    await store.send(.view(.tabSelected(.classResult))) {
      $0.selectedTab = .classResult
    }
    await store.send(.view(.tabSelected(.classResult)))
    await store.send(.view(.tabSelected(.feedback))) {
      $0.selectedTab = .feedback
    }
  }

  @Test
  func 결과_뒤로가기는_코디네이터에_닫기를_알린다() async {
    let store = TestStore(initialState: ClassReportFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())) {
      ClassReportFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate.dismiss)
  }

  @Test
  func 주입된_리포트를_불러오고_중복_요청하지_않는다() async {
    let room = ClassRoom.mockClosedSociety
    let report = MockClassReport.figma
    let instanceID = UUID(1)
    let requestID = UUID(2)
    let repository = MockClassRepository(
      rooms: [room],
      availableRooms: [],
      reports: [room.id: report]
    )
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: instanceID)) {
      ClassReportFeature()
    } withDependencies: {
      $0.classUseCase = repository
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch) {
      $0.requestID = requestID
    }
    await store.receive(\.inner.reportResponse) {
      $0.requestID = nil
      $0.report = report
      $0.sourceViewState = .ready
    }
    await store.receive(\.async.generateFeedback) {
      $0.feedbackContext = try! .personal(room: room, report: report, isOwner: false)
      $0.feedbackRequestID = requestID
      $0.isGeneratingFeedback = true
    }
    await store.receive(\.inner.feedbackResponse) {
      $0.feedbackRequestID = nil
      $0.isGeneratingFeedback = false
      $0.feedbackError = .modelNotReady
    }
    await store.send(.view(.onAppear))
    #expect(store.state.showsSummaryLayout)
  }

  @Test
  func 로딩_중_다시_나타나도_요청하지_않는다() async {
    var state = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID(8))
    state.requestID = UUID(18)
    let store = TestStore(initialState: state) { ClassReportFeature() }

    await store.send(.view(.onAppear))
  }

  @Test
  func 없는_리포트는_네_탭을_유지하는_사용불가_상태다() async {
    let room = ClassRoom.mockClosedSociety
    let requestID = UUID(3)
    let repository = MockClassRepository(rooms: [room], availableRooms: [], reports: [:])
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: UUID(4))) {
      ClassReportFeature()
    } withDependencies: {
      $0.classUseCase = repository
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch) {
      $0.requestID = requestID
    }
    await store.receive(\.inner.reportResponse) {
      $0.requestID = nil
      $0.sourceViewState = .ready
    }
    #expect(store.state.report == nil)
    #expect(!store.state.showsSummaryLayout)
    await store.send(.view(.tabSelected(.feedback))) {
      $0.selectedTab = .feedback
    }
  }

  @Test
  func 실패_후_재시도하고_늦은_응답은_무시한다() async {
    let room = ClassRoom.mockClosedSociety
    let instanceID = UUID(5)
    let requestID = UUID(6)
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: instanceID)) {
      ClassReportFeature()
    } withDependencies: {
      $0.classUseCase = repository
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch) {
      $0.requestID = requestID
    }
    await store.receive(\.inner.reportResponse) {
      $0.requestID = nil
      $0.sourceViewState = .failed
    }
    await store.send(.view(.onAppear))
    #expect(store.state.sourceViewState == .failed)
    await store.send(.view(.retryTapped))
    await store.receive(\.async.fetch) {
      $0.requestID = requestID
      $0.sourceViewState = .loading
    }
    await store.send(.inner(.reportResponse(
      instanceID: UUID(7),
      requestID: requestID,
      roomID: room.id,
      .success(MockClassReport.figma)
    )))
    await store.receive(\.inner.reportResponse) {
      $0.requestID = nil
      $0.sourceViewState = .failed
    }
  }

  @Test
  func 뒤로가기_후_지연된_응답은_상태를_바꾸지_않는다() async {
    let room = ClassRoom.mockClosedSociety
    let instanceID = UUID(9)
    let requestID = UUID(10)
    var state = ClassReportFeature.State(room: room, instanceID: instanceID)
    state.requestID = requestID
    let store = TestStore(initialState: state) { ClassReportFeature() }

    await store.send(.view(.backTapped)) {
      $0.requestID = nil
    }
    await store.receive(\.delegate.dismiss)
    await store.send(.inner(.reportResponse(
      instanceID: instanceID,
      requestID: requestID,
      roomID: room.id,
      .success(MockClassReport.figma)
    )))
  }

  @Test
  func 생성된_피드백만_표시하고_리포트_원본은_보존한다() async {
    let room = ClassRoom.mockClosedSociety
    let report = MockClassReport.figma
    let feedback = ClassAIPersonalFeedback(
      summaryTitle: "생성된 제목",
      summaryDetail: "생성된 분석",
      points: [
        .init(title: "첫 관점", detail: "첫 설명"),
        .init(title: "둘째 관점", detail: "둘째 설명"),
        .init(title: "셋째 관점", detail: "셋째 설명"),
      ],
      nextQuestion: "생성된 질문?",
      nextHint: "생성된 힌트"
    )
    let requestID = UUID(11)
    var state = ClassReportFeature.State(room: room, instanceID: UUID(12))
    state.report = report
    state.sourceViewState = .ready
    let store = TestStore(initialState: state) { ClassReportFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classAIFeedbackUseCase = MockClassAIFeedbackUseCase { context in
        #expect(context.kind == .studentPersonal)
        #expect(context.roomID == room.id)
        return .personal(feedback)
      }
    }

    await store.send(.async(.generateFeedback)) {
      $0.feedbackContext = try! .personal(room: room, report: report, isOwner: false)
      $0.feedbackRequestID = requestID
      $0.isGeneratingFeedback = true
    }
    await store.receive(\.inner.feedbackResponse) {
      $0.feedbackRequestID = nil
      $0.isGeneratingFeedback = false
      $0.feedback = feedback
    }
    #expect(store.state.feedbackViewState == .ready(feedback))
    #expect(store.state.report == report)
  }

  @Test
  func 일시적_실패는_보존된_리포트로_재시도하고_뒤로가기는_응답을_차단한다() async {
    let room = ClassRoom.mockClosedSociety
    let report = MockClassReport.figma
    let requestID = UUID(13)
    let instanceID = UUID(14)
    var state = ClassReportFeature.State(room: room, instanceID: instanceID)
    state.report = report
    state.sourceViewState = .ready
    let store = TestStore(initialState: state) { ClassReportFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classAIFeedbackUseCase = MockClassAIFeedbackUseCase { _ in
        throw ClassAIFeedbackError.modelNotReady
      }
    }

    await store.send(.async(.generateFeedback)) {
      $0.feedbackContext = try! .personal(room: room, report: report, isOwner: false)
      $0.feedbackRequestID = requestID
      $0.isGeneratingFeedback = true
    }
    await store.receive(\.inner.feedbackResponse) {
      $0.feedbackRequestID = nil
      $0.isGeneratingFeedback = false
      $0.feedbackError = .modelNotReady
    }
    #expect(store.state.feedbackViewState == .retryableFailure)
    await store.send(.view(.feedbackRetryTapped))
    await store.receive(\.async.generateFeedback) {
      $0.feedbackRequestID = requestID
      $0.isGeneratingFeedback = true
      $0.feedbackError = nil
    }
    await store.receive(\.inner.feedbackResponse) {
      $0.feedbackRequestID = nil
      $0.isGeneratingFeedback = false
      $0.feedbackError = .modelNotReady
    }
    await store.send(.view(.backTapped))
    await store.receive(\.delegate.dismiss)
    await store.send(.inner(.feedbackResponse(
      instanceID: instanceID,
      requestID: requestID,
      roomID: room.id,
      .failure(.modelNotReady),
      wasUnknown: false
    )))
    #expect(store.state.report == report)
  }

  @Test
  func 작성한_근거가_없으면_모델을_호출하지_않는다() async {
    let room = ClassRoom.mockClosedSociety
    let report = ClassReport(
      texts: [.aiSummaryDetail: "기존 고정 AI 문구"],
      myOpinions: [],
      initialVoteLeading: 0.5,
      finalVoteLeading: 0.5,
      layout: .summary
    )
    var state = ClassReportFeature.State(room: room, instanceID: UUID(15))
    state.report = report
    state.sourceViewState = .ready
    let store = TestStore(initialState: state) { ClassReportFeature() } withDependencies: {
      $0.classAIFeedbackUseCase = MockClassAIFeedbackUseCase { _ in
        Issue.record("근거가 없는 리포트에서 모델을 호출하면 안 됩니다")
        throw ClassAIFeedbackError.generationFailed
      }
    }

    await store.send(.async(.generateFeedback)) {
      $0.feedbackError = .insufficientInput
    }
    #expect(store.state.feedbackViewState == .unavailable)
    #expect(store.state.report == report)
  }

  @Test
  func 지원하지_않는_언어와_문맥_초과는_서로_다른_상태다() {
    var state = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID(16))
    state.feedbackError = .unsupportedLanguage
    #expect(state.feedbackViewState == .unavailable)
    state.feedbackError = .contextTooLong
    #expect(state.feedbackViewState == .failure)
  }

  @Test
  func AI_상태와_무관하게_서버_의견_목록을_보존한다() {
    var state = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID(17))
    state.report = MockClassReport.figma
    state.sourceViewState = .ready
    let opinions = state.myOpinions
    #expect(!opinions.isEmpty)
    state.isGeneratingFeedback = true
    #expect(state.myOpinions == opinions)
    state.isGeneratingFeedback = false
    for error in [ClassAIFeedbackError.deviceNotEligible, .modelNotReady, .generationFailed] {
      state.feedbackError = error
      #expect(state.myOpinions == opinions)
      #expect(state.myOpinionCount == opinions.count)
    }
  }
}

private extension UUID {
  init(_ value: UInt8) {
    self.init(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, value))
  }
}
