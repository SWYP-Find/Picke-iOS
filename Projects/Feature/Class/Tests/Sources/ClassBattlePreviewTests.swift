//
//  ClassBattlePreviewTests.swift
//  ClassTests
//
//  Created by Picke on 10/21/26.
//

import AudioPlayerServiceInterface
@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import HomeDomainInterface
import Testing

@MainActor
struct ClassBattlePreviewTests {
  @Test
  func 미리듣기는_60초에서_멈추고_오디오를_일시정지한다() async {
    let player = RecordingPreviewAudioPlayer()
    var state = ClassBattlePreviewFeature.State(battle: .mocks[0])
    state.isActive = true
    state.isAudioReady = true
    state.isPlaying = true
    state.audioDuration = 300
    state.currentTime = 59
    let store = TestStore(initialState: state) {
      ClassBattlePreviewFeature()
    } withDependencies: {
      $0.classBattlePreviewDependencies.audioPlayer = player
    }

    await store.send(.inner(.playerTimeUpdated(60.2))) {
      $0.currentTime = 60
      $0.isPlaying = false
      $0.hasFinished = true
    }
    await store.finish()
    #expect(await player.pauses == 1)
  }

  @Test
  func 탐색은_60초_구간에_고정하고_이전_틱을_무시한다() async {
    let player = RecordingPreviewAudioPlayer()
    var state = ClassBattlePreviewFeature.State(battle: .mocks[0])
    state.isActive = true
    state.isAudioReady = true
    state.currentTime = 52
    state.audioDuration = 240
    let store = TestStore(initialState: state) {
      ClassBattlePreviewFeature()
    } withDependencies: {
      $0.classBattlePreviewDependencies.audioPlayer = player
    }

    await store.send(.view(.seekForwardTapped)) {
      $0.currentTime = 60
      $0.pendingSeekTime = 60
    }
    await store.send(.inner(.playerTimeUpdated(52)))
    await store.finish()
    #expect(await player.seeks == [60])
  }

  @Test
  func 화면을_떠나면_재생을_멈추고_후속_틱을_무시한다() async {
    let player = RecordingPreviewAudioPlayer()
    var state = ClassBattlePreviewFeature.State(battle: .mocks[0])
    state.isActive = true
    state.isAudioReady = true
    state.isPlaying = true
    state.currentTime = 13
    let store = TestStore(initialState: state) {
      ClassBattlePreviewFeature()
    } withDependencies: {
      $0.classBattlePreviewDependencies.audioPlayer = player
    }

    await store.send(.view(.onDisappear)) {
      $0.isActive = false
      $0.isPlaying = false
    }
    await store.send(.inner(.playerTimeUpdated(18)))
    await store.finish()
    #expect(await player.pauses == 1)
  }

  @Test
  func 화면에_다시_들어오면_시간_관찰을_재시작한다() async {
    let player = RecordingPreviewAudioPlayer()
    var state = ClassBattlePreviewFeature.State(battle: .mocks[0])
    state.scenario = BattleScenario(
      battleId: state.battle.id,
      title: "미리 듣기",
      philosophers: [],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: [:],
      nodes: []
    )
    state.isAudioReady = true
    let instanceID = state.instanceID
    let store = TestStore(initialState: state) {
      ClassBattlePreviewFeature()
    } withDependencies: {
      $0.classBattlePreviewDependencies.audioPlayer = player
    }

    await store.send(.view(.onAppear)) { $0.isActive = true }
    await store.receive(\.async, .observeTime(instanceID))
    await store.send(.view(.onDisappear)) { $0.isActive = false }
    await store.finish()
  }

  @Test
  func 음원_로딩_중_화면을_떠났다가_돌아오면_로딩을_재시작한다() async throws {
    let player = RecordingPreviewAudioPlayer()
    let url = try #require(URL(string: "https://example.com/preview.mp3"))
    var state = ClassBattlePreviewFeature.State(battle: .mocks[0])
    state.scenario = BattleScenario(
      battleId: state.battle.id,
      title: "미리 듣기",
      philosophers: [],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: ["sample": url.absoluteString],
      nodes: []
    )
    let instanceID = state.instanceID
    let store = TestStore(initialState: state) {
      ClassBattlePreviewFeature()
    } withDependencies: {
      $0.classBattlePreviewDependencies.audioPlayer = player
    }

    await store.send(.view(.onAppear)) { $0.isActive = true }
    await store.receive(\.async, .loadAudio(url))
    await store.receive(\.inner, .audioLoaded(true, 300)) {
      $0.isAudioReady = true
      $0.audioDuration = 300
      $0.isPlaying = true
    }
    await store.receive(\.async, .observeTime(instanceID))
    await store.send(.view(.onDisappear)) {
      $0.isActive = false
      $0.isPlaying = false
    }
    await store.finish()
  }

  @Test
  func 짧은_음원의_마지막_틱에서도_재생_완료로_처리한다() async {
    let player = RecordingPreviewAudioPlayer()
    var state = ClassBattlePreviewFeature.State(battle: .mocks[0])
    state.isActive = true
    state.isAudioReady = true
    state.isPlaying = true
    state.audioDuration = 8
    let store = TestStore(initialState: state) {
      ClassBattlePreviewFeature()
    } withDependencies: {
      $0.classBattlePreviewDependencies.audioPlayer = player
    }

    await store.send(.inner(.playerTimeUpdated(7.8))) {
      $0.currentTime = 7.8
      $0.isPlaying = false
      $0.hasFinished = true
    }
    await store.finish()
    #expect(await player.pauses == 1)
  }

  @Test
  func 음원이_없는_시나리오는_대사만_표시하고_재생을_비활성화한다() async {
    var state = ClassBattlePreviewFeature.State(battle: .mocks[0])
    state.isActive = true
    let scenario = BattleScenario(
      battleId: state.battle.id,
      title: "시나리오 제목",
      philosophers: [],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: [:],
      nodes: [
        ScenarioNode(
          nodeId: 1,
          nodeName: "START",
          audioDuration: 120,
          autoNextNodeId: nil,
          scripts: [
            ScenarioScript(
              scriptId: 1,
              startTimeMs: 0,
              speakerType: .narrator,
              speakerName: "화자",
              text: "실제 대사"
            ),
          ],
          interactiveOptions: []
        ),
      ]
    )
    let store = TestStore(initialState: state) {
      ClassBattlePreviewFeature()
    }

    await store.send(.inner(.scenarioResponse(.success(scenario)))) {
      $0.scenario = scenario
      $0.viewState = .loaded
      $0.audioErrorMessage = "미리 들을 수 있는 음원이 없어요"
    }
    #expect(store.state.previewScripts.map(\.text) == ["실제 대사"])
    #expect(!store.state.isAudioReady)
  }
}

private actor RecordingPreviewAudioPlayer: AudioPlayerInterface {
  private(set) var pauses = 0
  private(set) var seeks: [TimeInterval] = []

  func load(url _: URL) async -> Bool {
    true
  }

  func play() async {}
  func pause() async {
    pauses += 1
  }

  func setPlaybackRate(_: Float) async {}
  func seek(to time: TimeInterval) async {
    seeks.append(time)
  }

  func duration() async -> TimeInterval {
    300
  }

  nonisolated func currentTimes() -> AsyncStream<TimeInterval> {
    AsyncStream { _ in }
  }
}
