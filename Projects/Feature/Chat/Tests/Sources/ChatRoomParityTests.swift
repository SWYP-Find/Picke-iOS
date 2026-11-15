//
//  ChatRoomParityTests.swift
//  ChatTests
//
//  Created by Picke on 11/10/26.
//

import AudioPlayerServiceInterface
@testable import Chat
import ComposableArchitecture
import Foundation
import HomeDomainInterface
import PickeSharedUI
import Testing

/// Android `ScenarioViewModel` 동작과 맞춘 부분.
@MainActor
struct ChatRoomParityTests {
  @Test
  func playbackRateCyclesLikeAndroid() {
    var state = ChatRoomFeature.State()
    var titles: [String] = []
    for _ in 0 ..< 4 {
      titles.append(state.playbackRateTitle)
      state.playbackRate = state.nextPlaybackRate
    }
    #expect(titles == ["1.0", "1.5", "2.0", "3.0"])
    #expect(state.playbackRate == 1)
  }

  @Test
  func scrubStopsAtListenedPosition() async {
    var state = Self.listeningState()
    state.maxListenedTime = 12
    let store = Self.store(state)

    await store.send(.view(.scrub(30)))
    #expect(store.state.currentTime == 12)
  }

  @Test
  func forwardIsBlockedWhileFinalVoteDialogIsShown() async {
    var state = Self.listeningState()
    state.currentTime = 5
    state.customAlert = .finalVote()
    let store = Self.store(state)

    #expect(store.state.isForwardEnabled == false)
    await store.send(.view(.seekForwardTapped))
    #expect(store.state.currentTime == 5)
  }

  @Test
  func reviewingShowsEveryLineAndDoesNotAskAgain() async {
    let store = Self.store(Self.listeningState())

    await store.send(.inner(.playerTimeUpdated(40)))
    #expect(store.state.customAlert == .finalVote())

    await store.send(.scope(.customAlert(.presented(.cancelTapped))))
    #expect(store.state.isReviewing)
    #expect(store.state.currentTime == 0)
    #expect(store.state.isPlaying)
    #expect(store.state.messages.count == 3)

    await store.send(.inner(.playerTimeUpdated(40)))
    #expect(store.state.customAlert == nil)
  }

  @Test
  func dismissingFinalVoteDialogGoesToFinalVote() async {
    var state = Self.listeningState()
    state.customAlert = .finalVote()
    let store = Self.store(state)

    await store.send(.scope(.customAlert(.dismiss)))
    await store.receive { action in
      guard case .delegate(.requestFinalVote(battleId: 990)) = action else { return false }
      return true
    }
  }

  @Test
  func tappingLineSeeksToItsStart() async throws {
    var state = Self.listeningState()
    state.currentTime = 25
    state.maxListenedTime = 25
    let store = Self.store(state)
    let second = try #require(store.state.messages.first { $0.text == "두 번째 대사" })

    await store.send(.view(.messageTapped(second.id)))
    #expect(store.state.currentTime == 10)
    #expect(store.state.isPlaying)
  }

  @Test
  func loadFailureShowsToastOnly() async {
    let store = Self.store(ChatRoomFeature.State())

    await store.send(.inner(.scenarioResponse(.failure(.noData))))
    #expect(store.state.toastMessage == "정보를 불러오지 못했어요")
    #expect(store.state.messages.isEmpty)
    #expect(store.state.battleTitle.isEmpty)
    #expect(store.state.totalDuration == 0)
  }
}

extension ChatRoomParityTests {
  private static func store(_ state: ChatRoomFeature.State) -> TestStoreOf<ChatRoomFeature> {
    let store = TestStore(initialState: state) {
      ChatRoomFeature()
    } withDependencies: {
      $0.audioPlayer = SilentAudioPlayer()
    }
    store.exhaustivity = .off
    return store
  }

  private static func listeningState() -> ChatRoomFeature.State {
    var state = ChatRoomFeature.State(battleId: 990)
    state.scenario = scenario
    state.currentNodeId = 1
    state.visibleNodeIds = [1]
    state.playerDuration = 40
    return state
  }

  private static let scenario = BattleScenario(
    battleId: 990,
    title: "테스트 배틀",
    philosophers: [],
    isInteractive: false,
    startNodeId: 1,
    recommendedPathKey: .common,
    audios: [:],
    nodes: [
      ScenarioNode(
        nodeId: 1,
        nodeName: "START",
        audioDuration: 40,
        autoNextNodeId: nil,
        scripts: [
          ScenarioScript(scriptId: 1, startTimeMs: 0, speakerType: .a, speakerName: "플라톤", text: "첫 번째 대사"),
          ScenarioScript(scriptId: 2, startTimeMs: 10000, speakerType: .b, speakerName: "사르트르", text: "두 번째 대사"),
          ScenarioScript(scriptId: 3, startTimeMs: 20000, speakerType: .a, speakerName: "플라톤", text: "세 번째 대사"),
        ],
        interactiveOptions: []
      ),
    ]
  )
}

private actor SilentAudioPlayer: AudioPlayerInterface {
  func setPlaybackRate(_: Float) async {}
  func load(url _: URL) async -> Bool {
    true
  }

  func play() async {}
  func pause() async {}
  func seek(to _: TimeInterval) async {}
  func duration() async -> TimeInterval {
    0
  }

  nonisolated func currentTimes() -> AsyncStream<TimeInterval> {
    AsyncStream { $0.finish() }
  }
}
