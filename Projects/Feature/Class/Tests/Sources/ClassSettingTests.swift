@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassSettingTests {
  private let battle = ClassBattleSummary.mocks[0]
  private let deadline = Date(timeIntervalSince1970: 1_800_000_000)

  @Test
  func 클래스명이_비어있으면_만들기를_누를_수_없다() {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.name = "   "
    #expect(state.canCreate == false)

    state.name = "2학년 3반"
    #expect(state.canCreate)
  }

  @Test
  func 마감일을_끄면_마감일_없이_클래스를_만든다() {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.name = " 2학년 3반 "
    state.isDeadlineEnabled = false

    #expect(state.creation?.name == "2학년 3반")
    #expect(state.creation?.deadline == .distantFuture)
    #expect(state.creation?.battleId == battle.id)
  }

  @Test
  func 클래스를_만들면_생성_델리게이트를_보낸다() async throws {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.name = "2학년 3반"
    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    }
    store.exhaustivity = .off

    await store.send(.view(.createTapped))
    try await store.receive(\.async, .create(#require(state.creation))) {
      $0.isLoading = true
    }
    await store.receive(\.inner.created) {
      $0.isLoading = false
    }
    await store.receive(\.delegate.created)
  }

  @Test
  func AI_질문_클래스_만들기는_안내를_표시하고_생성하지_않는다() async {
    var state = ClassSettingFeature.State(aiQuestion: ClassAIQuestion.examples[0], deadline: deadline)
    state.name = "2학년 3반"
    #expect(state.creation == nil)

    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    }
    await store.send(.view(.createTapped)) {
      $0.unavailableNotice = .init()
    }
    await store.send(.unavailableNotice(.presented(.dismissTapped))) {
      $0.unavailableNotice = nil
    }
  }
}
