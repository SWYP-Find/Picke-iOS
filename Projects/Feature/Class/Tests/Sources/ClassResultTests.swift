//
//  ClassResultTests.swift
//  ClassTests
//
//  Created by Picke on 11/20/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

/// Android `ClassResultViewModel`·`ClassResultUiState` 규칙 검증.
@MainActor
struct ClassResultTests {
  private let room = ClassRoom.mocks[0]

  private func loaded(
    hasSummaryTab: Bool,
    hasReportTab: Bool,
    insight: ClassResultInsightBoard? = nil
  ) -> ClassResultContent {
    ClassResultContent(
      className: "클래스",
      isInProgress: false,
      tag: "#철학",
      battleTitle: "배틀",
      deadline: Date(timeIntervalSince1970: 1_760_000_000),
      hasSummaryTab: hasSummaryTab,
      hasReportTab: hasReportTab,
      stats: .init(
        activeMemberCount: 4,
        completedCount: 2,
        participationRate: 50,
        commentWriterCount: 2,
        commentRate: 50,
        postVoteCount: 3,
        options: []
      ),
      insight: insight,
      report: hasReportTab ? ClassResultMyReportBoard(
        state: .succeeded,
        preOptionTitle: "찬성",
        postOptionTitle: "반대",
        perspectiveCount: 1,
        commentCount: 2,
        feedback: nil
      ) : nil,
      receivedLikeCount: hasReportTab ? 3 : nil
    )
  }

  @Test
  func 탭_바는_요약과_내_리포트가_모두_있을_때만_보인다() {
    var state = ClassResultFeature.State(room: room)

    state.loaded = loaded(hasSummaryTab: true, hasReportTab: true)
    #expect(state.isTabVisible)
    #expect(state.visibleTab == .summary)
    state.selectedTab = .report
    #expect(state.visibleTab == .report)

    // 운영자 참여 끔: 내 리포트 상태가 없으면 요약만, 탭 바 없음.
    state.loaded = loaded(hasSummaryTab: true, hasReportTab: false)
    #expect(!state.isTabVisible)
    #expect(state.visibleTab == .summary)

    // 멤버: 요약 탭 없이 내 리포트만.
    state.loaded = loaded(hasSummaryTab: false, hasReportTab: true)
    #expect(!state.isTabVisible)
    #expect(state.visibleTab == .report)
  }

  @Test
  func 인사이트_재시도는_실패이면서_재시도_가능할_때만_열린다() {
    var state = ClassResultFeature.State(room: room)
    state.loaded = loaded(
      hasSummaryTab: true,
      hasReportTab: false,
      insight: .init(state: .failed, insightText: nil, retryable: true)
    )
    #expect(state.isInsightRetryEnabled)
    state.isRequesting = true
    #expect(!state.isInsightRetryEnabled)

    state.isRequesting = false
    state.loaded?.insight = .init(state: .limited, insightText: nil, retryable: true)
    #expect(!state.isInsightRetryEnabled)
  }

  @Test
  func 결과를_불러오지_못하면_안드로이드_토스트를_띄운다() async {
    let store = TestStore(initialState: ClassResultFeature.State(room: room)) {
      ClassResultFeature()
    } withDependencies: {
      $0.classUseCase = MockClassRepository(rooms: [room], availableRooms: [])
    }

    await store.send(.view(.onAppear))
    await store.receive(\.inner, .loadFailed) {
      $0.isLoading = false
      $0.toastMessage = "정보를 불러오지 못했어요"
    }
  }

  @Test
  func 내_의견_보기는_클래스_ID로_내_의견_화면을_요청한다() async {
    var state = ClassResultFeature.State(room: room)
    state.isLoading = false
    state.loaded = loaded(hasSummaryTab: false, hasReportTab: true)
    let store = TestStore(initialState: state) { ClassResultFeature() }

    await store.send(.view(.myOpinionTapped))
    await store.receive(\.delegate, .openMyOpinions(classID: room.id))
  }

  @Test
  func 입장_비율은_0점1퍼센트_단위로_합이_100이_되게_나눈다() {
    #expect(ClassResultFormat.stanceRates([1, 2]) == [33.3, 66.7])
    #expect(ClassResultFormat.stanceRates([0, 0]) == nil)
    #expect(ClassResultFormat.rate(50) == "50")
    #expect(ClassResultFormat.rate(33.3) == "33.3")
  }
}
