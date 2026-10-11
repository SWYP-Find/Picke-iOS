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
    state.insight = MockClassOwnerDashboard.figma.insight
    state.report = MockClassOwnerDashboard.figma.report
    state.metrics = MockClassOwnerDashboard.figma.metrics
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

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchDashboard) {
      $0.requestID = requestID
      $0.isLoading = true
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.isLoading = false
      $0.hasLoaded = true
      $0.members = dashboard.members
      $0.opinions = dashboard.opinions
      $0.insight = dashboard.insight
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
      $0.isLoading = true
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.isLoading = false
      $0.hasLoaded = true
    }
    #expect(!store.state.loadFailed)
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
    state.isLoading = true
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
      $0.isLoading = false
    }
    await store.receive(\.delegate, .dismiss)
    await store.send(.inner(.dashboardResponse(
      instanceID: instanceID,
      requestID: requestID,
      roomID: room.id,
      .success(MockClassOwnerDashboard.figma)
    )))
    #expect(!store.state.hasLoaded)
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
      $0.isLoading = true
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.isLoading = false
      $0.hasLoaded = true
      $0.loadFailed = true
    }
    await store.send(.view(.retryTapped))
    await store.receive(\.async.fetchDashboard) {
      $0.requestID = requestID
      $0.isLoading = true
      $0.loadFailed = false
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.isLoading = false
      $0.loadFailed = true
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

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetchDashboard) {
      $0.requestID = requestID
      $0.isLoading = true
    }
    await store.receive(\.inner.dashboardResponse) {
      $0.requestID = nil
      $0.isLoading = false
      $0.hasLoaded = true
      $0.members = MockClassOwnerDashboard.figma.members
      $0.opinions = MockClassOwnerDashboard.figma.opinions
      $0.insight = MockClassOwnerDashboard.figma.insight
      $0.report = MockClassOwnerDashboard.figma.report
      $0.metrics = MockClassOwnerDashboard.figma.metrics
    }
    #expect(store.state.room.deadline == deadline)
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
