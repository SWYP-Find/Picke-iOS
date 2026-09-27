import HomeDomainInterface
import Testing

struct BattleScenarioTimelineTests {
  @Test
  func linearContentReachesClosingWithoutExplicitLink() {
    let scenario = makeScenario()
    #expect(scenario.nextNodeId(for: scenario.nodes[0]) == 12)
    #expect(scenario.nodeEndTime(for: scenario.nodes[0]) == 85)
    #expect(scenario.nextNodeId(for: scenario.nodes[1]) == nil)
  }

  @Test
  func interactiveContentDoesNotInferBranchFromArrayOrder() {
    let scenario = makeScenario(isInteractive: true)
    #expect(scenario.nextNodeId(for: scenario.nodes[0]) == nil)
  }

  @Test
  func explicitLinkTakesPrecedence() {
    let scenario = makeScenario(nextNodeId: 99)
    #expect(scenario.nextNodeId(for: scenario.nodes[0]) == 99)
  }

  private func makeScenario(
    isInteractive: Bool = false,
    nextNodeId: Int? = nil
  ) -> BattleScenario {
    BattleScenario(
      battleId: 5,
      title: "콘텐츠",
      philosophers: [],
      isInteractive: isInteractive,
      startNodeId: 11,
      recommendedPathKey: .common,
      audios: [:],
      nodes: [
        ScenarioNode(
          nodeId: 11,
          nodeName: "START",
          audioDuration: 90,
          autoNextNodeId: nextNodeId,
          scripts: [script(id: 1, startTimeMs: 0)],
          interactiveOptions: []
        ),
        ScenarioNode(
          nodeId: 12,
          nodeName: "CLOSING",
          audioDuration: 11,
          autoNextNodeId: nil,
          scripts: [script(id: 2, startTimeMs: 85_000)],
          interactiveOptions: []
        ),
      ]
    )
  }

  private func script(
    id: Int,
    startTimeMs: Int
  ) -> ScenarioScript {
    ScenarioScript(
      scriptId: id,
      startTimeMs: startTimeMs,
      speakerType: .narrator,
      speakerName: "나레이터",
      text: "마지막 안내입니다."
    )
  }
}
