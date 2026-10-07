@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassOwnerDashboardTests {
  @Test
  func 기본_상태에는_예시_멤버와_의견이_없다() {
    let state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0])
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
    var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0])
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
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State.preview(room: ClassRoom.mocks[0])) {
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
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State.preview(room: ClassRoom.mocks[0])) {
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
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State.preview(room: ClassRoom.mocks[0])) {
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
    var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0])
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
    var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0])
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

  #if DEBUG
    @Test
    func 미리보기_참여_수치와_멤버_목록이_같은_인원을_사용한다() {
      let state = ClassOwnerDashboardFeature.State.preview(room: ClassRoom.mocks[0])
      let participated = state.members.filter { $0.participationCount > 0 }.count

      #expect(state.members.count == 32)
      #expect(participated == 28)
      #expect(state.previewMetrics?.optionAVoteCount == 18)
      #expect(state.previewMetrics?.optionBVoteCount == 10)
      #expect(state.previewMetrics?.commentAuthorCount == 24)
    }
  #endif

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
