//
//  ChatTests.swift
//  Feature.ChatTests
//
//  Created by Roy on 2026-05-21.
//

@testable import Chat
import HomeDomainInterface
import Testing

struct ChatTests {
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
