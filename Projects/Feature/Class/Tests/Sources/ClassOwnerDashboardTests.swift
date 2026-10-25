//
//  ClassOwnerDashboardTests.swift
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
struct ClassOwnerDashboardTests {
  @Test
  func 서버_결과는_멤버별_활동을_추정하지_않고_집계만_보존한다() async {
    let room = ClassRoom.mocks[0]
    let requestID = UUID()
    var state = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    state.requestID = requestID
    let result = ClassResult(
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
        options: []
      ),
      myReportState: nil,
      insightState: nil
    )
    let store = TestStore(initialState: state) { ClassOwnerDashboardFeature() }

    await store.send(.inner(.resultResponse(
      instanceID: state.instanceID,
      requestID: requestID,
      roomID: room.id,
      .success(result)
    ))) {
      $0.requestID = nil
      $0.classResult = result
      $0.sourceViewState = .ready
    }
    #expect(store.state.members.isEmpty)
    #expect(store.state.metrics == nil)
  }

  private func fixtureState() -> ClassOwnerDashboardFeature.State {
    var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())
    state.members = MockClassOwnerDashboard.figma.members
    state.opinions = MockClassOwnerDashboard.figma.opinions
    state.dashboard = MockClassOwnerDashboard.figma
    state.report = MockClassOwnerDashboard.figma.report
    state.metrics = MockClassOwnerDashboard.figma.metrics
    state.sourceViewState = .ready
    return state
  }

  @Test
  func 기본_상태에는_예시_멤버와_의견이_없다() {
    let state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())
    #expect(state.members.isEmpty)
    #expect(state.opinions.isEmpty)
    #expect(state.visibleMembers.isEmpty)
    #expect(state.visibleOpinions.isEmpty)
    #expect(state.needsReviewViewState == .unavailable)
    #expect(state.highParticipationViewState == .unavailable)
    #expect(state.topOpinionViewState == .empty)
  }

  @Test
  func 참여_요약은_해당_멤버가_없으면_빈_상태로_표시한다() {
    var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())
    state.members = [
      ClassOwnerMember(id: 1, name: "첫 멤버", participationCount: 1),
      ClassOwnerMember(id: 2, name: "둘째 멤버", participationCount: 0),
    ]

    #expect(state.needsReviewViewState == .empty)
    #expect(state.highParticipationViewState == .loaded([state.members[0]]))

    state.members[0] = ClassOwnerMember(id: 1, name: "첫 멤버", participationCount: 0)
    #expect(state.highParticipationViewState == .empty)
  }

  @Test
  func 멤버_정렬과_검색을_함께_적용한다() async {
    let store = TestStore(initialState: fixtureState()) {
      ClassOwnerDashboardFeature()
    }

    await store.send(.view(.memberSortSelected(.participation))) {
      $0.memberSort = .participation
    }
    #expect(store.state.visibleMembers.prefix(3).map(\.participationCount) == [8, 7, 6])
    #expect(store.state.visibleMembers.filter { $0.participationCount > 0 }.count == 28)

    await store.send(.view(.searchTextChanged("김민지"))) {
      $0.searchText = "김민지"
    }
    #expect(store.state.visibleMembers.map(\.name) == ["김민지"])
  }

  @Test
  func 참여_상태_필터는_미참여_멤버만_표시한다() async {
    let store = TestStore(initialState: fixtureState()) {
      ClassOwnerDashboardFeature()
    }

    await store.send(.view(.memberFilterSelected(.notParticipated))) {
      $0.memberFilter = .notParticipated
    }
    #expect(store.state.visibleMembers.count == 4)
    #expect(store.state.visibleMembers.allSatisfy { $0.participationCount == 0 })
  }

  @Test
  func 피드백_대상_멤버를_전달한다() async {
    let store = TestStore(initialState: fixtureState()) {
      ClassOwnerDashboardFeature()
    }
    let member = store.state.members[0]

    await store.send(.view(.feedbackTapped(member.id)))
    await store.receive(\.delegate, .openFeedback(member))

    await store.send(.view(.memberTapped(member.id)))
    await store.receive(\.delegate, .openMemberDetail(member))
  }

  @Test
  func 의견_정렬은_인기순과_전달된_최신순을_구분한다() async {
    var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())
    state.opinions = [
      ClassOwnerOpinion(
        id: 1,
        author: "첫 의견",
        text: "A",
        replyCount: 1,
        recommendationCount: 1,
        createdAt: Date(timeIntervalSince1970: 200)
      ),
      ClassOwnerOpinion(
        id: 2,
        author: "둘째 의견",
        text: "B",
        replyCount: 3,
        recommendationCount: 3,
        createdAt: Date(timeIntervalSince1970: 100)
      ),
    ]
    let store = TestStore(initialState: state) { ClassOwnerDashboardFeature() }

    #expect(store.state.visibleOpinions.map(\.id) == [2, 1])
    #expect(store.state.topOpinionViewState == .loaded([state.opinions[1], state.opinions[1]]))
    await store.send(.view(.opinionFilterSelected(.latest))) {
      $0.opinionFilter = .latest
    }
    #expect(store.state.visibleOpinions.map(\.id) == [1, 2])
  }

  @Test
  func 주요_의견은_추천과_대댓글의_서로_다른_일위를_보여준다() {
    var state = fixtureState()
    let best = highlightOpinion(id: 1, recommendations: 10, replies: 1)
    let discussed = highlightOpinion(id: 2, recommendations: 2, replies: 8)
    let runnerUp = highlightOpinion(id: 3, recommendations: 9, replies: 3)
    state.opinions = [runnerUp, discussed, best]
    #expect(state.topOpinionViewState == .loaded([best, discussed]))
  }

  @Test
  func 두_기준의_일위가_같으면_각_역할에_같은_의견을_보여준다() {
    var state = fixtureState()
    let winner = highlightOpinion(id: 1, recommendations: 10, replies: 8)
    state.opinions = [highlightOpinion(id: 2, recommendations: 2, replies: 3), winner]
    #expect(state.topOpinionViewState == .loaded([winner, winner]))
  }

  @Test
  func 주요_의견_동률은_입력_순서와_무관하게_작은_ID를_선택한다() {
    var state = fixtureState()
    let first = highlightOpinion(id: 1, recommendations: 10, replies: 8)
    let second = highlightOpinion(id: 2, recommendations: 10, replies: 8)
    state.opinions = [second, first]
    #expect(state.topOpinionViewState == .loaded([first, first]))
    state.opinions.reverse()
    #expect(state.topOpinionViewState == .loaded([first, first]))
  }

  @Test
  func 대댓글이_없으면_논쟁_카드를_보여주지_않는다() {
    var state = fixtureState()
    let best = highlightOpinion(id: 1, recommendations: 10, replies: 0)
    state.opinions = [best, highlightOpinion(id: 2, recommendations: 2, replies: 0)]
    #expect(state.topOpinionViewState == .loaded([best]))
  }

  @Test
  func 의견이_하나면_BEST만_보여준다() {
    var state = fixtureState()
    let only = highlightOpinion(id: 1, recommendations: 10, replies: 8)
    state.opinions = [only]
    #expect(state.topOpinionViewState == .loaded([only]))
  }

  private func highlightOpinion(
    id: Int,
    recommendations: Int,
    replies: Int
  ) -> ClassOwnerOpinion {
    return ClassOwnerOpinion(
      id: id,
      author: "참여자",
      text: "의견 \(id)",
      replyCount: replies,
      recommendationCount: recommendations
    )
  }

  @Test
  func 정렬_기준이_없는_의견은_필터를_적용하지_않는다() async {
    var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())
    state.opinions = [ClassOwnerOpinion(id: 1, author: "첫 의견", text: "A", replyCount: 2)]
    let store = TestStore(initialState: state) { ClassOwnerDashboardFeature() }

    #expect(!store.state.canSortOpinions(.popular))
    #expect(!store.state.canSortOpinions(.latest))
    #expect(store.state.activeOpinionFilter == nil)
    #expect(store.state.topOpinionViewState == .unavailable)
    await store.send(.view(.opinionFilterSelected(.latest)))
    #expect(store.state.opinionFilter == .popular)
    #expect(store.state.visibleOpinions.map(\.id) == [1])
  }

  @Test
  func 주입된_참여_수치와_멤버_목록이_같은_인원을_사용한다() {
    let state = fixtureState()
    let participated = state.members.filter { $0.participationCount > 0 }.count

    #expect(state.members.count == 32)
    #expect(participated == 28)
    #expect(state.metrics?.optionAVoteCount == 18)
    #expect(state.metrics?.optionBVoteCount == 10)
    #expect(state.metrics?.commentAuthorCount == 24)
    let voteCount = (state.metrics?.optionAVoteCount ?? 0)
      + (state.metrics?.optionBVoteCount ?? 0)
    #expect(participated == voteCount)
  }

  private struct ResultStub: ClassResultInterface {
    let result: Result<ClassResult, ClassError>
    var feedback: ClassAIPersonalFeedback? = nil
    var insight: ClassAIInsight? = nil

    func fetch(roomID _: Int) async throws -> ClassResult {
      try result.get()
    }

    func fetchPersonal(roomID _: Int) async throws -> ClassAIPersonalFeedback {
      guard let feedback else { throw ClassAIFeedbackError.temporarilyUnavailable }
      return feedback
    }

    func fetchInsight(roomID _: Int) async throws -> ClassAIInsight {
      guard let insight else { throw ClassAIFeedbackError.temporarilyUnavailable }
      return insight
    }

    func retryInsight(roomID _: Int) async throws {
      throw ClassAIFeedbackError.temporarilyUnavailable
    }
  }

  private func serverResult(
    _ room: ClassRoom,
    options: [ClassResultOption] = []
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
        options: options
      ),
      myReportState: nil,
      insightState: nil
    )
  }

  @Test
  func 운영자_화면은_서버_결과만_불러오고_멤버별_활동을_생성하지_않는다() async {
    let room = ClassRoom.mocks[0]
    let result = serverResult(room)
    let requestID = UUID()
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())) {
      ClassOwnerDashboardFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classResultUseCase = ResultStub(result: .success(result))
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchDashboard)
    await store.receive(\.inner.resultResponse)

    #expect(store.state.classResult == result)
    #expect(store.state.sourceViewState == .ready)
    #expect(store.state.members.isEmpty)
    #expect(store.state.opinions.isEmpty)
    #expect(store.state.metrics == nil)
    await store.send(.view(.onAppear))
  }

  @Test
  func 참여_운영자는_서버_인사이트와_개인_리포트를_함께_받는다() async {
    let room = ClassRoom.mocks[0]
    let requestID = UUID()
    var state = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    state.requestID = requestID
    let result = ClassResult(
      classID: room.id,
      closed: true,
      closeAt: room.deadline,
      stats: serverResult(room).stats,
      myReportState: "SUCCEEDED",
      insightState: "SUCCEEDED"
    )
    let feedback = ClassAIPersonalFeedback(
      summaryTitle: "개인 결과",
      summaryDetail: "참여 분석",
      points: [],
      nextQuestion: "다음 질문",
      nextHint: "",
      perspectiveCount: 2
    )
    let insight = ClassAIInsight(text: "운영 인사이트")
    let store = TestStore(initialState: state) { ClassOwnerDashboardFeature() } withDependencies: {
      $0.uuid = .constant(UUID())
      $0.classResultUseCase = ResultStub(
        result: .success(result),
        feedback: feedback,
        insight: insight
      )
    }
    store.exhaustivity = .off

    await store.send(.inner(.resultResponse(
      instanceID: state.instanceID,
      requestID: requestID,
      roomID: room.id,
      .success(result)
    )))
    await store.receive(\.async.generateInsight)
    await store.receive(\.async.generatePersonal)
    await store.receive(\.inner.insightResponse)
    await store.receive(\.inner.feedbackResponse)
    #expect(store.state.generatedInsight == insight.text)
    #expect(store.state.generatedFeedback == feedback)
    #expect(store.state.myOpinionCount == 2)
    await store.send(.view(.tabSelected(.report)))
    await store.send(.view(.myOpinionsTapped))
    await store.receive(\.delegate.openMyOpinions)
  }

  @Test
  func 서버_현황_표시값은_State에서_계산한다() {
    let room = ClassRoom.mocks[0]
    let option = ClassResultOption(id: 1, title: "찬성", preVoteCount: 2, postVoteCount: 3, postVoteRatio: 60)
    let result = serverResult(room, options: [option])
    var state = ClassOwnerDashboardFeature.State(room: room)
    state.classResult = result
    let stats = result.stats
    #expect(state.serverParticipationRate == "\(stats.participationRate.formatted(.number.precision(.fractionLength(1))))%")
    #expect(state.serverParticipationCount == "\(stats.completedCount) / \(stats.activeMemberCount)명")
    #expect(state.serverParticipationProgress == stats.participationRate / 100)
    #expect(state.serverOptionSummaries[option.id] == "3명 · 60.0%")
  }

  @Test
  func 대기_중인_운영자_인사이트와_개인_피드백을_다시_확인한다() async {
    let room = ClassRoom.mocks[0]
    let result = serverResult(room)
    let feedback = ClassAIPersonalFeedback(
      summaryTitle: "완료",
      summaryDetail: "상세",
      points: [],
      nextQuestion: "다음 질문",
      nextHint: ""
    )
    var state = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    state.classResult = result
    state.sourceViewState = .ready
    state.insightError = .modelNotReady
    state.feedbackError = .modelNotReady
    let store = TestStore(initialState: state) { ClassOwnerDashboardFeature() } withDependencies: {
      $0.uuid = .constant(UUID())
      $0.classResultUseCase = ResultStub(
        result: .success(result),
        feedback: feedback,
        insight: ClassAIInsight(text: "운영 인사이트")
      )
    }
    store.exhaustivity = .off

    await store.send(.view(.insightRetryTapped))
    await store.receive(\.async.generateInsight)
    await store.receive(\.inner.insightResponse)
    #expect(store.state.insightViewState == .ready("운영 인사이트"))

    await store.send(.view(.feedbackRetryTapped))
    await store.receive(\.async.generatePersonal)
    await store.receive(\.inner.feedbackResponse)
    #expect(store.state.feedbackViewState == .ready(feedback))
  }

  @Test
  func 참여_운영자는_피드백_대기나_실패_중에도_내_의견을_열_수_있다() async {
    let room = ClassRoom.mocks[0]
    let result = ClassResult(
      classID: room.id,
      closed: true,
      closeAt: room.deadline,
      stats: serverResult(room).stats,
      myReportState: "PENDING",
      insightState: nil
    )

    for error in [ClassAIFeedbackError.modelNotReady, .generationFailed] {
      var state = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
      state.classResult = result
      state.selectedTab = .report
      state.sourceViewState = .ready
      state.feedbackError = error
      #expect(state.canOpenMyOpinions)
      let store = TestStore(initialState: state) { ClassOwnerDashboardFeature() }
      await store.send(.view(.myOpinionsTapped))
      await store.receive(\.delegate.openMyOpinions)
    }
  }

  @Test
  func 서버_결과_실패는_재시도할_수_있는_상태가_된다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())) {
      ClassOwnerDashboardFeature()
    } withDependencies: {
      $0.uuid = .constant(UUID())
      $0.classResultUseCase = ResultStub(result: .failure(.network("연결 실패")))
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchDashboard)
    await store.receive(\.inner.resultResponse)
    #expect(store.state.sourceViewState == .failed)
    #expect(store.state.sourceError == .network("연결 실패"))
    await store.send(.view(.retryTapped))
    await store.receive(\.async.fetchDashboard)
    await store.receive(\.inner.resultResponse)
    #expect(store.state.sourceViewState == .failed)
  }

  @Test
  func 서버_연동_전에는_피드백_등록을_전송하지_않는다() async {
    let store = TestStore(initialState: ClassFeedbackComposeFeature.State(
      room: ClassRoom.mocks[0],
      memberName: "김민지"
    )) {
      ClassFeedbackComposeFeature()
    }

    await store.send(.binding(.set(\.feedback, "좋은 의견이에요"))) {
      $0.feedback = "좋은 의견이에요"
    }
    await store.send(.view(.submitTapped)) {
      $0.customAlert = .alert(
        title: "전송 준비 중",
        message: "서버 연동 전이라 피드백을 전송할 수 없습니다.",
        cancelTitle: ""
      )
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.customAlert = nil
    }
  }
}
