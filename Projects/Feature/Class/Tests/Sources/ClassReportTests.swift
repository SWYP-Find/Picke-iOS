@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassReportTests {
  @Test
  func 결과_탭을_선택하면_해당_내용으로_바뀐다() async {
    let store = TestStore(initialState: ClassReportFeature.State(room: ClassRoom.mocks[0])) {
      ClassReportFeature()
    }

    await store.send(.view(.tabSelected(.classResult))) {
      $0.selectedTab = .classResult
    }
  }

  @Test
  func 결과_뒤로가기는_코디네이터에_닫기를_알린다() async {
    let store = TestStore(initialState: ClassReportFeature.State(room: ClassRoom.mocks[0])) {
      ClassReportFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate.dismiss)
  }
}
