//
//  ClassBattlePreviewReferenceFixture.swift
//  Class
//
//  Created by Picke on 10/22/26.
//

import ClassDomainInterface
import HomeDomainInterface

/// Shared reference state for the visual test and the full-screen audit host.
public enum ClassBattlePreviewReferenceFixture {
  public static func makeState() -> ClassBattlePreviewFeature.State {
    let battle = ClassBattleSummary(
      id: 901,
      title: "인간은 본래 선한가, 악한가?",
      summary: "",
      philosopherA: "플라톤",
      optionATitle: "선하다",
      philosopherB: "사르트르",
      optionBTitle: "악하다",
      category: .philosophy,
      level: .high,
      audioDuration: 60,
      viewCount: 0
    )
    var state = ClassBattlePreviewFeature.State(battle: battle)
    state.isActive = true
    state.isAudioReady = true
    state.isPlaying = true
    state.viewState = .loaded
    state.currentTime = 13
    state.scenario = BattleScenario(
      battleId: battle.id,
      title: battle.title,
      philosophers: [
        .init(label: "A", name: "플라톤", stance: "", imageUrl: ""),
        .init(label: "B", name: "사르트르", stance: "", imageUrl: ""),
      ],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: [:],
      nodes: [ScenarioNode(
        nodeId: 1,
        nodeName: "START",
        audioDuration: 60,
        autoNextNodeId: nil,
        scripts: [
          ScenarioScript(
            scriptId: 1,
            startTimeMs: 0,
            speakerType: .a,
            speakerName: "플라톤",
            text: "이건 기만입니다. 하늘 아래 모든 사물은 그에 걸맞은 완벽한 목적과 형상, 즉 '이데아'를 가지고 있습니다."
          ),
          ScenarioScript(
            scriptId: 2,
            startTimeMs: 5000,
            speakerType: .b,
            speakerName: "사르트르",
            text: "플라톤 선생님, 당신은 사물에 '영혼'이 미리 정해져 있다고 믿는군요. 하지만 사물은 그저 그곳에 존재할 뿐입니다."
          ),
          ScenarioScript(
            scriptId: 3,
            startTimeMs: 10000,
            speakerType: .a,
            speakerName: "플라톤",
            text: "이건 기만입니다. 하늘 아래 모든 사물은 그에 걸맞은 완벽한 목적과 형상, 즉 '이데아'를 가지고 있습니다."
          ),
          ScenarioScript(
            scriptId: 4,
            startTimeMs: 12000,
            speakerType: .b,
            speakerName: "사르트르",
            text: "플라톤 선생님, 당신은 사물에 '영혼'이 미리 정해져 있다고 믿는군요. 하지만 사물은 그저 그곳에 존재할 뿐입니다."
          ),
        ],
        interactiveOptions: []
      )]
    )
    return state
  }
}
