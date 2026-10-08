@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassAIVoteTests {
  @Test
  func 사전_투표_완료자는_선택한_옵션으로_AI_채팅에_진입한다() async {
    let store = TestStore(initialState: ClassAIVoteFeature.State(
      room: ClassRoom.mocks[0],
      battleID: -1_000_001
    )) {
      ClassAIVoteFeature()
    }

    await store.send(.inner(.voteLoaded(.success(.init(status: .con, step: .listening))))) {
      $0.selectedOptionID = 2
      $0.hasSubmitted = true
    }
    await store.send(.view(.submitTapped))
    await store.receive(\.delegate, .voteSubmitted(
      battleID: -1_000_001,
      selectedOptionID: 2,
      hasCompletedPostVote: false
    ))
  }

  @Test
  func 사후_투표_완료자는_채팅을_건너뛰도록_알린다() async {
    let store = TestStore(initialState: ClassAIVoteFeature.State(
      room: ClassRoom.mocks[0],
      battleID: -1_000_001
    )) {
      ClassAIVoteFeature()
    }

    await store.send(.inner(.voteLoaded(.success(.init(status: .pro, step: .completed))))) {
      $0.selectedOptionID = 1
      $0.hasSubmitted = true
      $0.hasCompletedPostVote = true
    }
    await store.send(.view(.submitTapped))
    await store.receive(\.delegate, .voteSubmitted(
      battleID: -1_000_001,
      selectedOptionID: 1,
      hasCompletedPostVote: true
    ))
  }
}
