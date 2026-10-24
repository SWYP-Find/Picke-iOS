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

    func fetch(roomID _: Int) async throws -> ClassResult {
      try result.get()
    }

    func fetchPersonal(roomID _: Int) async throws -> ClassAIPersonalFeedback {
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
    reportState: String?
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
        options: [.init(id: 31, title: "창작이다", preVoteCount: 8, postVoteCount: 6, postVoteRatio: 54.5)]
      ),
      myReportState: reportState,
      insightState: nil
    )
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
