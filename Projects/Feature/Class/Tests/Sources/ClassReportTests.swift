//
//  ClassReportTests.swift
//  ClassTests
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassReportTests {
  private struct ResultStub: ClassResultInterface {
    let result: Result<ClassResult, ClassError>
    let feedback: ClassAIPersonalFeedback?

    init(
      result: Result<ClassResult, ClassError>,
      feedback: ClassAIPersonalFeedback? = nil
    ) {
      self.result = result
      self.feedback = feedback
    }

    func fetchResult(roomID _: Int) async throws -> ClassResult {
      try result.get()
    }

    func fetchPersonalResult(roomID _: Int) async throws -> ClassAIPersonalFeedback {
      guard let feedback else { throw ClassAIFeedbackError.temporarilyUnavailable }
      return feedback
    }

    func fetchInsight(roomID _: Int) async throws -> ClassAIInsight {
      throw ClassAIFeedbackError.temporarilyUnavailable
    }

    func retryInsight(roomID _: Int) async throws {
      throw ClassAIFeedbackError.temporarilyUnavailable
    }
  }

  private func result(
    room: ClassRoom,
    reportState: String?,
    postVoteRatio: Double = 54.5
  ) -> ClassResult {
    ClassResult(
      classID: room.id,
      closed: true,
      closeAt: room.deadline,
      stats: .init(
        activeMemberCount: 12,
        completedCount: 10,
        participationRate: 83.3,
        commentWriterCount: 9,
        commentRate: 75,
        postVoteCount: 11,
        options: [.init(id: 31, title: "창작이다", preVoteCount: 8, postVoteCount: 6, postVoteRatio: postVoteRatio)]
      ),
      myReportState: reportState,
      insightState: nil
    )
  }

  @Test
  func 서버_결과_표시값은_State에서_계산한다() throws {
    var state = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID())
    state.classResult = result(room: .mockClosedSociety, reportState: "SUCCEEDED")
    #expect(state.serverActiveMemberCount == "12")
    #expect(state.serverCompletedCount == "10")
    #expect(state.serverPostVoteCount == "11")
    #expect(state.serverParticipationSummary == "참여율 83.3% · 의견 작성률 75.0%")
    #expect(state.serverParticipationRate == "83.3%")
    #expect(state.serverCommentRate == "75%")
    #expect(state.serverParticipationCount == "10 / 12명")
    #expect(state.serverCommentCount == "9 / 12명")
    #expect(abs(state.serverParticipationProgress - 0.833) < 0.0001)
    #expect(abs(state.serverCommentProgress - 0.75) < 0.0001)
    let option = try #require(state.classResult?.stats.options.first)
    #expect(state.serverOptionCounts[option.id] == "사전 8 · 사후 6")
    #expect(state.serverDistributionTotalText == "11명")
    #expect(abs(state.serverDistributionProgress - 0.545) < 0.0001)
    #expect(state.serverDistributionOptionCountTexts[option.id] == "6명")
    #expect(state.serverDistributionOptionRatioTexts[option.id] == "54.5%")

    state.classResult = result(
      room: .mockClosedSociety,
      reportState: "SUCCEEDED",
      postVoteRatio: -10
    )
    #expect(state.serverDistributionProgress == 0)
    state.classResult = result(
      room: .mockClosedSociety,
      reportState: "SUCCEEDED",
      postVoteRatio: 110
    )
    #expect(state.serverDistributionProgress == 1)
  }

  @Test
  func 개인_결과의_입장_및_활동_표시값은_State에서_계산한다() {
    var state = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID())
    #expect(state.personalPerspectiveCountText == "—")
    #expect(state.personalCommentCountText == "—")

    state.feedback = ClassAIPersonalFeedback(
      summaryTitle: "요약",
      summaryDetail: "상세",
      points: [],
      nextQuestion: "다음 질문",
      nextHint: "",
      preOption: .init(id: 1, title: "찬성"),
      postOption: .init(id: 2, title: "반대"),
      perspectiveCount: 3,
      commentCount: 0
    )
    #expect(state.personalPerspectiveCountText == "3")
    #expect(state.personalCommentCountText == "0")

    state.voteHistory = ClassVoteHistory(
      battleTitle: "배틀",
      preVote: .init(optionID: 1, label: "A", title: "찬성"),
      postVote: .init(optionID: 2, label: "B", title: "반대"),
      status: .completed,
      opinionChanged: nil
    )
    #expect(state.personalOpinionChangeTitle == "입장 변경")

    state.voteHistory = ClassVoteHistory(
      battleTitle: "배틀",
      preVote: .init(optionID: 1, label: "A", title: "찬성"),
      postVote: .init(optionID: 1, label: "A", title: "찬성"),
      status: .completed,
      opinionChanged: nil
    )
    #expect(state.personalOpinionChangeTitle == "입장 유지")

    state.voteHistory = ClassVoteHistory(
      battleTitle: "배틀",
      preVote: .init(optionID: 1, label: "A", title: "찬성"),
      postVote: nil,
      status: .completed,
      opinionChanged: nil
    )
    #expect(state.personalPostVoteTitle == "반대")
    #expect(state.personalOpinionChangeTitle == "입장 변경")

    state.feedback = ClassAIPersonalFeedback(
      summaryTitle: "요약",
      summaryDetail: "상세",
      points: [],
      nextQuestion: "다음 질문",
      nextHint: "",
      preOption: nil,
      postOption: .init(id: 2, title: "반대"),
      perspectiveCount: 3,
      commentCount: 0
    )
    #expect(state.personalPreVoteTitle == "찬성")
    #expect(state.personalPostVoteTitle == "반대")
    #expect(state.personalOpinionChangeTitle == "입장 변경")

    state.feedback = ClassAIPersonalFeedback(
      summaryTitle: "요약",
      summaryDetail: "상세",
      points: [],
      nextQuestion: "다음 질문",
      nextHint: "",
      preOption: .init(id: 1, title: "찬성"),
      postOption: .init(id: 1, title: "찬성"),
      perspectiveCount: 3,
      commentCount: 0
    )
    #expect(state.personalPostVoteTitle == "찬성")
    #expect(state.personalOpinionChangeTitle == "입장 유지")
  }

  @Test
  func 뒤로가기와_닫기는_리포트를_닫는다() async {
    let state = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID())
    let backStore = TestStore(initialState: state) { ClassReportFeature() }
    await backStore.send(.view(.backTapped))
    await backStore.receive(\.delegate.dismiss)

    let closeStore = TestStore(initialState: state) { ClassReportFeature() }
    await closeStore.send(.view(.closeTapped))
    await closeStore.receive(\.delegate.dismiss)
  }

  @Test
  func 서버_결과가_있어도_개인_리포트_권한이_없으면_생성하지_않는다() async {
    let room = ClassRoom.mockClosedSociety
    let response = result(room: room, reportState: nil)
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: UUID())) {
      ClassReportFeature()
    } withDependencies: {
      $0.uuid = .constant(UUID())
      $0.classResultUseCase = ResultStub(result: .success(response))
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch)
    await store.receive(\.inner.resultResponse)

    #expect(store.state.classResult == response)
    #expect(store.state.sourceViewState == .ready)
    #expect(store.state.feedback == nil)
    #expect(store.state.report == nil)
  }

  @Test
  func 레거시_리포트_응답도_개인_결과_권한이_없으면_AI를_조회하지_않는다() async {
    let room = ClassRoom.mockClosedSociety
    let requestID = UUID()
    var state = ClassReportFeature.State(room: room, instanceID: UUID())
    state.requestID = requestID
    state.classResult = result(room: room, reportState: nil)
    let report = MockClassReport.figma
    let store = TestStore(initialState: state) { ClassReportFeature() }

    await store.send(.inner(.reportResponse(
      instanceID: state.instanceID,
      requestID: requestID,
      roomID: room.id,
      .success(report)
    ))) {
      $0.requestID = nil
      $0.report = report
      $0.sourceViewState = .ready
    }
    await store.finish()
  }

  @Test
  func 참여자의_개인_리포트는_서버_응답으로_표시한다() async {
    let room = ClassRoom.mockClosedSociety
    let response = result(room: room, reportState: "SUCCEEDED")
    let feedback = ClassAIPersonalFeedback(
      summaryTitle: "서버 제목",
      summaryDetail: "서버 분석",
      points: [.init(title: "강점", detail: "근거")],
      nextQuestion: "다음 질문?",
      nextHint: ""
    )
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: UUID())) {
      ClassReportFeature()
    } withDependencies: {
      $0.uuid = .constant(UUID())
      $0.classResultUseCase = ResultStub(
        result: .success(response),
        feedback: feedback
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch)
    await store.receive(\.inner.resultResponse)
    await store.receive(\.async.generateFeedback)
    await store.receive(\.inner.feedbackResponse)

    #expect(store.state.classResult == response)
    #expect(store.state.feedback == feedback)
    #expect(store.state.feedbackViewState == .ready(feedback))
    await store.send(.view(.myOpinionsTapped))
    await store.receive(\.delegate.openMyOpinions)
  }

  @Test
  func 개인_결과가_로딩_중이어도_내_의견으로_이동한다() async {
    let room = ClassRoom.mockClosedSociety
    var state = ClassReportFeature.State(room: room, instanceID: UUID())
    state.classResult = result(room: room, reportState: "PENDING")
    state.sourceViewState = .ready
    let store = TestStore(initialState: state) { ClassReportFeature() }
    #expect(store.state.myOpinionsButtonTitle == "내가 남긴 의견 보기")
    await store.send(.view(.myOpinionsTapped))
    await store.receive(\.delegate.openMyOpinions)
  }

  @Test
  func 대기_중인_개인_피드백을_다시_확인하면_완료_결과를_받는다() async {
    let room = ClassRoom.mockClosedSociety
    let feedback = ClassAIPersonalFeedback(
      summaryTitle: "완료",
      summaryDetail: "상세",
      points: [],
      nextQuestion: "다음 질문",
      nextHint: ""
    )
    var state = ClassReportFeature.State(room: room, instanceID: UUID())
    state.classResult = result(room: room, reportState: "PENDING")
    state.sourceViewState = .ready
    state.feedbackError = .modelNotReady
    let store = TestStore(initialState: state) { ClassReportFeature() } withDependencies: {
      $0.uuid = .constant(UUID())
      $0.classResultUseCase = ResultStub(result: .success(state.classResult!), feedback: feedback)
    }
    store.exhaustivity = .off

    await store.send(.view(.feedbackRetryTapped))
    await store.receive(\.async.generateFeedback)
    await store.receive(\.inner.feedbackResponse)
    #expect(store.state.feedbackViewState == .ready(feedback))
  }

  @Test
  func 결과_조회_오류는_실패_상태로_남는다() async {
    let store = TestStore(initialState: ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID())) {
      ClassReportFeature()
    } withDependencies: {
      $0.uuid = .constant(UUID())
      $0.classResultUseCase = ResultStub(result: .failure(.network("연결 실패")))
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch)
    await store.receive(\.inner.resultResponse)

    #expect(store.state.sourceViewState == .failed)
    #expect(store.state.classResult == nil)
    #expect(store.state.sourceError == .network("연결 실패"))
  }

  @Test
  func 결과_열람_기간_만료는_일반_피드백_부족과_구분한다() async {
    let room = ClassRoom.mockClosedSociety
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: UUID())) {
      ClassReportFeature()
    } withDependencies: {
      $0.uuid = .constant(UUID())
      $0.classResultUseCase = ResultStub(result: .failure(.resultExpired))
    }
    store.exhaustivity = .off
    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch)
    await store.receive(\.inner.resultResponse)
    #expect(store.state.sourceError == .resultExpired)
  }
}
