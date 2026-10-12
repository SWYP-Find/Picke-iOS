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
    #expect(store.state.topOpinionViewState == .loaded([state.opinions[1], state.opinions[0]]))
    await store.send(.view(.opinionFilterSelected(.latest))) {
      $0.opinionFilter = .latest
    }
    #expect(store.state.visibleOpinions.map(\.id) == [1, 2])
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

  @Test
  func 주입된_대시보드_데이터를_로드하고_다시_나타나도_재요청하지_않는다() async {
    let room = ClassRoom.mocks[0]
    let dashboard = ClassOwnerDashboardData(
      members: [ClassOwnerMember(id: 87, name: "맞춤 멤버", participationCount: 2)],
      opinions: [ClassOwnerOpinion(id: 91, author: "맞춤 작성자", text: "맞춤 의견", replyCount: 0)],
      report: MockClassReport.figma,
      metrics: ClassParticipationMetrics(commentAuthorCount: 1, optionAVoteCount: 1, optionBVoteCount: 0)
    )
    let requestID = UUID()
    let instanceID = UUID()
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State(room: room, instanceID: instanceID)) {
      ClassOwnerDashboardFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classUseCase = MockClassRepository(rooms: [room], dashboards: [room.id: dashboard])
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchDashboard) {
      $0.requestID = requestID
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.sourceViewState = .ready
      $0.dashboard = dashboard
      $0.members = dashboard.members
      $0.opinions = dashboard.opinions
      $0.report = dashboard.report
      $0.metrics = dashboard.metrics
    }
    await store.send(.view(.onAppear))
    #expect(store.state.visibleMembers.map(\.name) == ["맞춤 멤버"])
    #expect(store.state.visibleOpinions.map(\.text) == ["맞춤 의견"])
  }

  @Test
  func 데이터가_없으면_성공한_빈_상태로_남는다() async {
    let room = ClassRoom.mocks[0]
    let requestID = UUID()
    let instanceID = UUID()
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State(room: room, instanceID: instanceID)) {
      ClassOwnerDashboardFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classUseCase = MockClassRepository(rooms: [room], dashboards: [:])
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchDashboard) {
      $0.requestID = requestID
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.sourceViewState = .ready
    }
    #expect(store.state.sourceViewState == .ready)
    #expect(store.state.members.isEmpty)
    #expect(store.state.report == nil)
    #expect(store.state.metrics == nil)
  }

  @Test
  func 오래된_응답과_뒤로가기_후_응답은_무시한다() async {
    let room = ClassRoom.mocks[0]
    let instanceID = UUID()
    let requestID = UUID()
    var state = ClassOwnerDashboardFeature.State(room: room, instanceID: instanceID)
    state.requestID = requestID
    let store = TestStore(initialState: state) {
      ClassOwnerDashboardFeature()
    }
    let staleResponse = ClassOwnerDashboardFeature.Action.inner(.dashboardResponse(
      instanceID: instanceID,
      requestID: UUID(),
      roomID: room.id,
      .success(MockClassOwnerDashboard.figma)
    ))
    await store.send(staleResponse)
    await store.send(.view(.backTapped)) {
      $0.requestID = nil
    }
    await store.receive(\.delegate, .dismiss)
    await store.send(.inner(.dashboardResponse(
      instanceID: instanceID,
      requestID: requestID,
      roomID: room.id,
      .success(MockClassOwnerDashboard.figma)
    )))
    #expect(store.state.sourceViewState == .loading)
    #expect(store.state.members.isEmpty)
  }

  @Test
  func 실패는_오류로_표시하고_재시도는_새_요청을_시작한다() async {
    let room = ClassRoom.mocks[0]
    let instanceID = UUID()
    let requestID = UUID()
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State(room: room, instanceID: instanceID)) {
      ClassOwnerDashboardFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classUseCase = MockClassRepository(rooms: [], dashboards: [:])
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchDashboard) {
      $0.requestID = requestID
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.sourceViewState = .failed
    }
    await store.send(.view(.onAppear))
    #expect(store.state.sourceViewState == .failed)
    await store.send(.view(.retryTapped))
    await store.receive(\.async.fetchDashboard) {
      $0.requestID = requestID
      $0.sourceViewState = .loading
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.sourceViewState = .failed
    }
  }

  @Test
  func 마감일을_변경한_방도_기존_대시보드를_로드한다() async throws {
    let repository = MockClassRepository()
    let original = ClassRoom.mocks[0]
    let deadline = original.deadline.addingTimeInterval(86400)
    let updated = try await repository.updateDeadline(id: original.id, deadline: deadline)
    #expect(updated.deadline == deadline)
    let instanceID = UUID()
    let requestID = UUID()
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State(room: updated, instanceID: instanceID)) {
      ClassOwnerDashboardFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classUseCase = repository
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchDashboard) {
      $0.requestID = requestID
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.sourceViewState = .ready
      $0.dashboard = MockClassOwnerDashboard.figma
      $0.members = MockClassOwnerDashboard.figma.members
      $0.opinions = MockClassOwnerDashboard.figma.opinions
      $0.report = MockClassOwnerDashboard.figma.report
      $0.metrics = MockClassOwnerDashboard.figma.metrics
    }
    #expect(store.state.room.deadline == deadline)
  }

  @Test
  func 학급_인사이트_실패와_개인_피드백_성공은_독립적이다() async {
    let room = ClassRoom.mocks[0]
    let dashboard = MockClassOwnerDashboard.figma
    let requestID = UUID()
    let feedback = ClassAIPersonalFeedback(
      summaryTitle: "생성된 제목",
      summaryDetail: "생성된 개인 분석",
      points: [
        .init(title: "첫째", detail: "설명1"),
        .init(title: "둘째", detail: "설명2"),
        .init(title: "셋째", detail: "설명3"),
      ],
      nextQuestion: "다음 질문?",
      nextHint: "다음 힌트"
    )
    var state = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    state.dashboard = dashboard
    state.report = dashboard.report
    state.members = dashboard.members
    state.opinions = dashboard.opinions
    state.metrics = dashboard.metrics
    state.sourceViewState = .ready
    let store = TestStore(initialState: state) { ClassOwnerDashboardFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classAIFeedbackUseCase = MockClassAIFeedbackUseCase { context in
        switch context.kind {
        case .classInsight: throw ClassAIFeedbackError.modelNotReady
        case .ownerPersonal: return .personal(feedback)
        case .studentPersonal: throw ClassAIFeedbackError.generationFailed
        }
      }
    }

    await store.send(.async(.generateInsight)) {
      $0.insightContext = try! .classInsight(room: room, dashboard: dashboard)
      $0.insightRequestID = requestID
      $0.isGeneratingInsight = true
    }
    await store.receive(\.inner.insightResponse) {
      $0.insightRequestID = nil
      $0.isGeneratingInsight = false
      $0.insightError = .modelNotReady
    }
    await store.send(.view(.insightRetryTapped))
    await store.receive(\.async.generateInsight) {
      $0.insightRequestID = requestID
      $0.isGeneratingInsight = true
      $0.insightError = nil
    }
    await store.receive(\.inner.insightResponse) {
      $0.insightRequestID = nil
      $0.isGeneratingInsight = false
      $0.insightError = .modelNotReady
    }
    await store.send(.async(.generatePersonal)) {
      $0.feedbackContext = try! .personal(room: room, report: dashboard.report!, isOwner: true)
      $0.feedbackRequestID = requestID
      $0.isGeneratingFeedback = true
    }
    await store.receive(\.inner.feedbackResponse) {
      $0.feedbackRequestID = nil
      $0.isGeneratingFeedback = false
      $0.generatedFeedback = feedback
    }
    #expect(store.state.insightViewState == .retryableFailure)
    #expect(store.state.feedbackViewState == .ready(feedback))
    #expect(store.state.metrics == dashboard.metrics)
    #expect(store.state.opinions == dashboard.opinions)
    #expect(store.state.generatedInsight == nil)
  }

  @Test
  func 주입된_학급_인사이트만_AI_영역에_나타난다() async {
    let room = ClassRoom.mocks[0]
    let dashboard = MockClassOwnerDashboard.figma
    let requestID = UUID()
    var state = ClassOwnerDashboardFeature.State(room: room, instanceID: UUID())
    state.dashboard = dashboard
    state.sourceViewState = .ready
    let store = TestStore(initialState: state) { ClassOwnerDashboardFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classAIFeedbackUseCase = MockClassAIFeedbackUseCase { context in
        #expect(context.kind == .classInsight)
        #expect(context.roomID == room.id)
        return .classInsight("생성된 학급 인사이트")
      }
    }
    await store.send(.async(.generateInsight)) {
      $0.insightContext = try! .classInsight(room: room, dashboard: dashboard)
      $0.insightRequestID = requestID
      $0.isGeneratingInsight = true
    }
    await store.receive(\.inner.insightResponse) {
      $0.insightRequestID = nil
      $0.isGeneratingInsight = false
      $0.generatedInsight = "생성된 학급 인사이트"
    }
    #expect(store.state.insightViewState == .ready("생성된 학급 인사이트"))
    #expect(store.state.generatedInsight != dashboard.insight)
  }

  @Test
  func AI_상태와_무관하게_운영자의_서버_의견_목록을_보존한다() {
    var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())
    state.report = MockClassOwnerDashboard.figma.report
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
