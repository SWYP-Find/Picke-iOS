@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassOwnerDashboardTests {
  @Test
  func 멤버_정렬과_검색을_함께_적용한다() async {
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0])) {
      ClassOwnerDashboardFeature()
    }

    await store.send(.view(.memberSortSelected(.participation))) {
      $0.memberSort = .participation
    }
    #expect(store.state.visibleMembers.map(\.participationCount) == [8, 7, 6, 5, 4, 3])

    await store.send(.view(.searchTextChanged("김민지"))) {
      $0.searchText = "김민지"
    }
    #expect(store.state.visibleMembers.map(\.name) == ["김민지"])
  }

  @Test
  func 피드백_대상_멤버를_전달한다() async {
    let store = TestStore(initialState: ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0])) {
      ClassOwnerDashboardFeature()
    }
    let member = store.state.members[0]

    await store.send(.view(.feedbackTapped(member.id)))
    await store.receive(\.delegate, .openFeedback(member))
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
      $0.showUnavailableAlert = true
    }
  }
}
