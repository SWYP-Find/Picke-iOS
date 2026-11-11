//
//  BattleParityTests.swift
//  BattleTests
//
//  Created by Picke on 11/10/26.
//

@testable import Battle
import BattleDomainInterface
import ComposableArchitecture
import Foundation
import Testing

/// Android `TodayBattleViewModel` 동작과 맞춘 부분.
@MainActor
struct BattleParityTests {
  @Test
  func durationRoundsUpToMinutes() {
    #expect(DailyBattle.from(Self.info(audioDuration: 61)).durationText == "2분")
    #expect(DailyBattle.from(Self.info(audioDuration: 120)).durationText == "2분")
    #expect(DailyBattle.from(Self.info(audioDuration: 0)).durationText == "0분")
  }

  @Test
  func showsOnlyFirstBattle() async {
    let store = Self.store()
    let page = TodayBattlePage(items: [Self.info(battleId: 1), Self.info(battleId: 2)], totalCount: 2)

    await store.send(.inner(.todayResponse(.success(page))))
    #expect(store.state.battles.map(\.battleId) == [1])
  }

  @Test
  func tappingSelectedOptionKeepsSelection() async {
    let store = Self.store()

    await store.send(.view(.optionTapped(battleId: 1, optionId: 7)))
    await store.send(.view(.optionTapped(battleId: 1, optionId: 7)))
    #expect(store.state.selectedOptionByBattle[1] == 7)
  }

  @Test
  func enteringFreshBattleSubmitsPreVoteThenOpensChat() async {
    var state = BattleFeature.State()
    state.selectedOptionByBattle = [1: 7]
    let store = Self.store(state)

    await store.send(.view(.enterBattleTapped(battleId: 1)))
    #expect(store.state.isEntering)
    #expect(!store.state.isEnterEnabled(for: 1))

    await store.send(.inner(.entryStepResponse(battleId: 1, optionId: 7, .success(.none))))
    await store.receive(\.async, .submitPreVote(battleId: 1, optionId: 7))
    await store.receive(\.inner)
    await store.receive(\.delegate, .openBattle(battleId: 1))
    #expect(!store.state.isEntering)
  }

  @Test
  func enteringJoinedBattleOpensPerspective() async {
    var state = BattleFeature.State()
    state.isEntering = true
    let store = Self.store(state)

    await store.send(.inner(.entryStepResponse(battleId: 1, optionId: 7, .success(.postVote))))
    await store.receive(\.delegate, .openPerspective(battleId: 1))
    #expect(!store.state.isEntering)
  }

  @Test
  func stepLookupFailureStillSubmitsPreVote() async {
    let store = Self.store()

    await store.send(.inner(.entryStepResponse(battleId: 1, optionId: 7, .failure(.noData))))
    await store.receive(\.async, .submitPreVote(battleId: 1, optionId: 7))
  }

  @Test
  func preVoteFailureShowsToast() async {
    let store = Self.store()

    await store.send(.inner(.preVoteResponse(battleId: 1, .failure(.insufficientPoints))))
    #expect(store.state.toastMessage == "포인트가 부족합니다.")
    await store.send(.inner(.preVoteResponse(battleId: 1, .failure(.serverError(500)))))
    #expect(store.state.toastMessage == "요청을 처리하지 못했어요")
  }
}

extension BattleParityTests {
  private static func store(_ state: BattleFeature.State = .init()) -> TestStoreOf<BattleFeature> {
    let store = TestStore(initialState: state) {
      BattleFeature()
    } withDependencies: {
      $0.battleUseCase = MockBattleRepository()
    }
    store.exhaustivity = .off
    return store
  }

  private static func info(
    battleId: Int = 1,
    audioDuration: Int = 60
  ) -> BattleInfo {
    BattleInfo(
      battleId: battleId,
      title: "제목",
      summary: "요약",
      thumbnailUrl: "",
      viewCount: 0,
      participantsCount: 0,
      audioDuration: audioDuration,
      tags: [],
      options: []
    )
  }
}
