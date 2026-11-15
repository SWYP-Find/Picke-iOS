//
//  PreVoteParityTests.swift
//  ChatTests
//
//  Created by Picke on 11/10/26.
//

@testable import Chat
import BattleDomainInterface
import ComposableArchitecture
import Foundation
import PickeSharedUI
import Testing

/// Android `VoteViewModel` 동작과 맞춘 부분.
@MainActor
struct PreVoteParityTests {
  @Test
  func tappingSelectedOptionKeepsSelection() async {
    var state = PreVoteFeature.State(battleId: 41)
    state.battle = .mock
    let store = TestStore(initialState: state) { PreVoteFeature() }

    await store.send(.view(.optionTapped(optionId: 1))) {
      $0.selectedOptionId = 1
    }
    await store.send(.view(.optionTapped(optionId: 1)))
  }

  @Test
  func detailFailureShowsToastAndNotFound() async {
    let store = TestStore(initialState: PreVoteFeature.State(battleId: 41)) { PreVoteFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.battleDetailResponse(.failure(.noData))))
    #expect(store.state.toastMessage == "정보를 불러오지 못했어요")
    #expect(store.state.isBattleNotFound)
  }

  @Test
  func preVoteFailureShowsActionFailedToast() async {
    let store = TestStore(initialState: PreVoteFeature.State(battleId: 41)) { PreVoteFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.preVoteResponse(.failure(.serverError(500)))))
    #expect(store.state.toastMessage == "요청을 처리하지 못했어요")
  }

  @Test
  func insufficientPointsShowsDialogAndOpensExplore() async {
    let store = TestStore(initialState: PreVoteFeature.State(battleId: 41)) { PreVoteFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.preVoteResponse(.failure(.insufficientPoints))))
    #expect(store.state.customAlert == .pointShortage())
    #expect(store.state.toastMessage == nil)

    await store.send(.scope(.customAlert(.presented(.confirmTapped))))
    await store.receive(\.delegate, .openExplore)
    #expect(store.state.customAlert == nil)
  }

  @Test
  func postVoteInsufficientPointsStaysOnScreen() async {
    let store = TestStore(
      initialState: PreVoteFeature.State(battleId: 41, voteMode: .post)
    ) { PreVoteFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.postVoteResponse(.failure(.insufficientPoints))))
    #expect(store.state.customAlert == .pointShortage())
  }
}
