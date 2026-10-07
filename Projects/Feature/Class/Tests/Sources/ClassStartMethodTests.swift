@testable import Class
import ComposableArchitecture
import Testing

@MainActor
struct ClassStartMethodTests {
  @Test
  func 기존_콘텐츠를_선택하면_주제_설정으로_넘긴다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.continueTapped))
    await store.receive(\.delegate.existingContentSelected)
  }

  @Test
  func 내_주제로_시작하면_AI_경로를_요청한다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.methodTapped(.ownTopic))) {
      $0.selectedMethod = .ownTopic
    }
    await store.send(.view(.continueTapped))
    await store.receive(\.delegate.ownTopicSelected)
  }

  @Test
  func 뒤로_가면_화면_닫기를_요청한다() async {
    let store = TestStore(initialState: ClassStartMethodFeature.State()) {
      ClassStartMethodFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate.dismiss)
  }
}
