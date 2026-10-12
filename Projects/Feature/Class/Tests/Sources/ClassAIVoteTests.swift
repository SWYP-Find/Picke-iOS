//
//  ClassAIVoteTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

import BattleDomainInterface
@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassAIVoteTests {
  private let instanceID = UUID(0)
  private let requestID = UUID(1)
  private let battleID = -1_000_001

  private func initialState() -> ClassAIVoteFeature.State {
    ClassAIVoteFeature.State(
      room: ClassRoom.mocks[0],
      battleID: battleID,
      instanceID: instanceID
    )
  }

  @Test
  func 처음에는_로딩이며_조회_전에는_선택과_제출을_막는다() async {
    var state = initialState()
    state.selectedOptionID = 1
    #expect(state.viewState == .loading)
    #expect(!state.canSubmit)
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    await store.send(.view(.optionTapped(2)))
    await store.send(.view(.submitTapped))
  }

  @Test
  func 첫_조회_성공_후_다시_나타나도_조회하지_않는다() async {
    let store = TestStore(initialState: initialState()) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.battleUseCase = MockBattleRepository()
    }
    await store.send(.view(.onAppear)) {
      $0.loadRequestID = requestID
    }
    await store.receive(\.inner, .voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .success(.init(status: .none, step: .none))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
    }
    #expect(store.state.viewState == .loaded)
    await store.send(.view(.onAppear))
    await store.send(.view(.optionTapped(1))) { $0.selectedOptionID = 1 }
    #expect(store.state.canSubmit)
  }

  @Test
  func 조회중_중복_등장과_재시도는_요청을_추가하지_않는다() async {
    var state = initialState()
    state.loadRequestID = requestID
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    await store.send(.view(.onAppear))
    await store.send(.view(.retryTapped))
  }

  @Test
  func 조회_실패_후_재시도하면_투표를_선택할_수_있다() async {
    var state = initialState()
    state.loadRequestID = requestID
    let retryID = UUID(2)
    let store = TestStore(initialState: state) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(retryID)
      $0.battleUseCase = MockBattleRepository()
    }
    await store.send(.inner(.voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .failure(.noData)
    ))) {
      $0.loadRequestID = nil
      $0.viewState = .error
      $0.errorMessage = "투표 상태를 불러오지 못했어요. 다시 시도해 주세요."
    }
    #expect(store.state.viewState == .error)
    await store.send(.view(.optionTapped(1)))
    await store.send(.view(.retryTapped)) {
      $0.loadRequestID = retryID
      $0.viewState = .loading
      $0.errorMessage = nil
    }
    await store.receive(\.inner, .voteLoaded(
      instanceID: instanceID,
      requestID: retryID,
      battleID: battleID,
      .success(.init(status: .none, step: .none))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
    }
  }

  @Test
  func 이전_화면과_요청과_배틀의_응답은_무시한다() async {
    var state = initialState()
    state.loadRequestID = requestID
    state.submitRequestID = requestID
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    for identity in [
      (UUID(2), requestID, battleID),
      (instanceID, UUID(2), battleID),
      (instanceID, requestID, battleID - 1),
    ] {
      await store.send(.inner(.voteLoaded(
        instanceID: identity.0,
        requestID: identity.1,
        battleID: identity.2,
        .success(.init(status: .pro, step: .completed))
      )))
      await store.send(.inner(.voteSubmitted(
        instanceID: identity.0,
        requestID: identity.1,
        battleID: identity.2,
        .success(.init(voteId: 1, status: .created))
      )))
    }
  }

  @Test
  func 뒤로가기_후_늦은_응답은_화면을_변경하지_않는다() async {
    var state = initialState()
    state.loadRequestID = requestID
    state.submitRequestID = requestID
    state.isSubmitting = true
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    await store.send(.view(.backTapped)) {
      $0.loadRequestID = nil
      $0.submitRequestID = nil
      $0.isSubmitting = false
    }
    await store.receive(\.delegate, .dismiss)
    await store.send(.inner(.voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .failure(.noData)
    )))
    await store.send(.inner(.voteSubmitted(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .success(.init(voteId: 1, status: .created))
    )))
  }

  @Test
  func 조회된_새_투표는_저장_성공_후에만_이동을_알린다() async {
    var state = initialState()
    state.viewState = .loaded
    state.selectedOptionID = 2
    let store = TestStore(initialState: state) { ClassAIVoteFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.battleUseCase = MockBattleRepository()
    }
    await store.send(.view(.submitTapped)) {
      $0.isSubmitting = true
      $0.submitRequestID = requestID
    }
    await store.receive(\.inner, .voteSubmitted(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .success(.init(voteId: 0, status: .none))
    )) {
      $0.submitRequestID = nil
      $0.isSubmitting = false
      $0.hasSubmitted = true
    }
    await store.receive(\.delegate, .voteSubmitted(
      battleID: battleID,
      selectedOptionID: 2,
      hasCompletedPostVote: false
    ))
  }

  @Test(arguments: [false, true])
  func 기존_투표자는_사후투표_완료_여부에_맞춰_진입한다(completed: Bool) async {
    var state = initialState()
    state.loadRequestID = requestID
    let store = TestStore(initialState: state) { ClassAIVoteFeature() }
    await store.send(.inner(.voteLoaded(
      instanceID: instanceID,
      requestID: requestID,
      battleID: battleID,
      .success(.init(status: completed ? .pro : .con, step: completed ? .completed : .listening))
    ))) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
      $0.selectedOptionID = completed ? 1 : 2
      $0.hasSubmitted = true
      $0.hasCompletedPostVote = completed
    }
    await store.send(.view(.submitTapped))
    await store.receive(\.delegate, .voteSubmitted(
      battleID: battleID,
      selectedOptionID: completed ? 1 : 2,
      hasCompletedPostVote: completed
    ))
  }
}
