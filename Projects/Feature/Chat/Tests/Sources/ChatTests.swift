//
//  ChatTests.swift
//  ChatTests
//
//  Created by Picke on 2026-05-21.
//

@testable import Chat
import AudioPlayerServiceInterface
import ComposableArchitecture
import Foundation
import HomeDomainInterface
import Testing

struct ChatTests {
  @Test
  func commentComposerStartsCollapsedAndOpensForEditing() async {
    let store = TestStore(initialState: CommentFeature.State(battleId: 901)) {
      CommentFeature()
    }

    #expect(store.state.isComposerExpanded == false)
    await store.send(.view(.composeTapped)) {
      $0.isComposerExpanded = true
    }
    await store.send(.view(.composeDismissed)) {
      $0.isComposerExpanded = false
    }
  }

  @Test
  func dismissingEditedCommentClearsDraftAndEditTarget() async {
    var state = CommentFeature.State(battleId: 901)
    state.isComposerExpanded = true
    state.editingPerspectiveId = 42
    state.commentText = "수정 중"
    let store = TestStore(initialState: state) {
      CommentFeature()
    }

    await store.send(.view(.composeDismissed)) {
      $0.isComposerExpanded = false
      $0.editingPerspectiveId = nil
      $0.commentText = ""
    }
  }

  @Test
  func chatExample() {
    // This is an example of a test case.
    #expect(true)
  }

  @Test
  func chatLogicTest() {
    let result = true
    #expect(result == true)
  }

  @Test
  func chatRoomMessagesRemainHiddenUntilTheirTimelinePosition() {
    var state = ChatRoomFeature.State(battleId: 901)
    state.scenario = makeScenario()
    state.currentNodeId = 1
    state.visibleNodeIds = [1]

    state.currentTime = 1
    #expect(state.messages.map(\.text) == ["첫 번째 문장."])

    state.currentTime = 6
    #expect(state.messages.map(\.text) == ["첫 번째 문장.", "두 번째 문장."])
  }

  @Test
  func chatRoomMessagesDoNotFallbackToMockContentBeforeScenarioLoads() {
    let state = ChatRoomFeature.State(battleId: 902)

    #expect(state.messages.isEmpty)
    #expect(state.audioUrl == nil)
  }

  @Test
  func chatRoomMessagesFollowDistinctScriptStartTimes() {
    var state = ChatRoomFeature.State(battleId: 903)
    state.scenario = makeScenario(scripts: [
      ScenarioScript(scriptId: 11, startTimeMs: 0, speakerType: .narrator, speakerName: "해설", text: "시작"),
      ScenarioScript(scriptId: 12, startTimeMs: 7000, speakerType: .narrator, speakerName: "해설", text: "나중"),
    ])
    state.visibleNodeIds = [1]

    state.currentTime = 6
    #expect(state.messages.map(\.text) == ["시작"])
    state.currentTime = 7
    #expect(state.messages.map(\.text) == ["시작", "나중"])
    #expect(state.messages.last?.speaker.side == .center)
  }

  @Test @MainActor
  func playbackRateSelectionForwardsWithoutStartingPausedAudio() async {
    let player = RecordingChatAudioPlayer()
    let store = TestStore(initialState: ChatRoomFeature.State(battleId: 904)) {
      ChatRoomFeature()
    } withDependencies: {
      $0.audioPlayer = player
    }

    #expect(ChatRoomFeature.State.supportedPlaybackRates == [1, 1.25, 1.5, 2])
    #expect(store.state.playbackRateTitle == "1.0")
    await store.send(.view(.playbackRateSelected(1.25))) {
      $0.playbackRate = 1.25
    }
    await store.finish()
    #expect(store.state.playbackRateTitle == "1.25")
    #expect(store.state.isPlaying == false)
    #expect(await player.events == [.rate(1.25)])
  }

  @Test @MainActor
  func unsupportedPlaybackRatesAreIgnored() async {
    let player = RecordingChatAudioPlayer()
    let store = TestStore(initialState: ChatRoomFeature.State(battleId: 905)) {
      ChatRoomFeature()
    } withDependencies: {
      $0.audioPlayer = player
    }

    for rate in [Float(0), 1.75, .nan, .infinity, -.infinity] {
      await store.send(.view(.playbackRateSelected(rate)))
    }
    await store.finish()
    #expect(store.state.playbackRate == 1)
    #expect(await player.events.isEmpty)
  }

  @Test @MainActor
  func newChatLoadRestoresDefaultRateBeforeLoading() async {
    let player = RecordingChatAudioPlayer()
    let previousStore = TestStore(initialState: ChatRoomFeature.State(battleId: 906)) {
      ChatRoomFeature()
    } withDependencies: {
      $0.audioPlayer = player
    }
    await previousStore.send(.view(.playbackRateSelected(2))) {
      $0.playbackRate = 2
    }
    await previousStore.finish()

    let newStore = TestStore(initialState: ChatRoomFeature.State(battleId: 907)) {
      ChatRoomFeature()
    } withDependencies: {
      $0.audioPlayer = player
    }
    await newStore.send(.async(.loadAudio(URL(string: "https://example.com/audio.mp3")!))) {
      $0.isPlaying = true
    }
    await newStore.finish()

    #expect(newStore.state.playbackRate == 1)
    #expect(await player.events == [.rate(2), .rate(1), .load, .play])
  }

  @Test @MainActor
  func existingChatSubscriptionRestoresSelectedRate() async {
    let player = RecordingChatAudioPlayer()
    var state = ChatRoomFeature.State(battleId: 908)
    state.playbackRate = 1.5
    let store = TestStore(initialState: state) {
      ChatRoomFeature()
    } withDependencies: {
      $0.audioPlayer = player
    }

    let subscription = await store.send(.async(.subscribePlayer))
    await player.waitForSubscription()
    #expect(await player.events == [.rate(1.5), .subscribe])
    await subscription.cancel()
    await store.finish()
  }

  @Test @MainActor
  func doubleSpeedSeekAcceptsTheNextTickWithoutAdvancingOnStaleTime() async {
    let player = RecordingChatAudioPlayer()
    var state = ChatRoomFeature.State(battleId: 909)
    state.playbackRate = 2
    state.pendingSeekTime = 15
    state.currentTime = 15
    let store = TestStore(initialState: state) {
      ChatRoomFeature()
    } withDependencies: {
      $0.audioPlayer = player
    }

    await store.send(.inner(.playerTimeUpdated(2)))
    await store.send(.inner(.playerTimeUpdated(15.6))) {
      $0.pendingSeekTime = nil
      $0.currentTime = 15.6
    }
    await store.send(.inner(.playerTimeUpdated(16.1))) {
      $0.currentTime = 16.1
    }
    await store.finish()
  }

  private func makeScenario(scripts: [ScenarioScript]? = nil) -> BattleScenario {
    BattleScenario(
      battleId: 901,
      title: "테스트 배틀",
      philosophers: [],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: ["COMMON": "https://example.com/audio.mp3"],
      nodes: [
        ScenarioNode(
          nodeId: 1,
          nodeName: "START",
          audioDuration: 10,
          autoNextNodeId: nil,
          scripts: scripts ?? [
            ScenarioScript(
              scriptId: 1,
              startTimeMs: 0,
              speakerType: .narrator,
              speakerName: "나레이터",
              text: "첫 번째 문장. 두 번째 문장."
            ),
          ],
          interactiveOptions: []
        ),
      ]
    )
  }
}

private actor RecordingChatAudioPlayer: AudioPlayerInterface {
  enum Event: Equatable {
    case rate(Float)
    case load
    case play
    case subscribe
  }

  private(set) var events: [Event] = []
  private var subscriptionContinuation: CheckedContinuation<Void, Never>?
  private var hasSubscribed = false

  func setPlaybackRate(_ rate: Float) async {
    events.append(.rate(rate))
  }

  func load(url _: URL) async -> Bool {
    events.append(.load)
    return true
  }

  func play() async {
    events.append(.play)
  }

  func pause() async {}
  func seek(to _: TimeInterval) async {}
  func duration() async -> TimeInterval { 0 }

  nonisolated func currentTimes() -> AsyncStream<TimeInterval> {
    AsyncStream { _ in
      Task { await self.recordSubscription() }
    }
  }

  func waitForSubscription() async {
    if hasSubscribed { return }
    await withCheckedContinuation { subscriptionContinuation = $0 }
  }

  private func recordSubscription() {
    events.append(.subscribe)
    hasSubscribed = true
    subscriptionContinuation?.resume()
    subscriptionContinuation = nil
  }
}
