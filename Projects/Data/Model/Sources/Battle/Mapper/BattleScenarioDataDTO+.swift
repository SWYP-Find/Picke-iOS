//
//  BattleScenarioDataDTO+.swift
//  Model
//

import Entity
import Foundation

public extension BattleScenarioDataDTO {
  func toDomain() -> BattleScenario {
    BattleScenario(
      battleId: battleId,
      title: title,
      philosophers: philosophers.map { $0.toDomain() },
      isInteractive: isInteractive,
      startNodeId: startNodeId,
      recommendedPathKey: RecommendedPathKey(rawValue: recommendedPathKey),
      audios: audios,
      nodes: nodes.map { $0.toDomain() }
    )
  }
}

public extension ScenarioPhilosopherDTO {
  func toDomain() -> ScenarioPhilosopher {
    ScenarioPhilosopher(label: label, name: name, stance: stance, imageUrl: imageUrl)
  }
}

public extension ScenarioNodeDTO {
  func toDomain() -> ScenarioNode {
    ScenarioNode(
      nodeId: nodeId,
      nodeName: nodeName,
      audioDuration: audioDuration,
      autoNextNodeId: autoNextNodeId,
      scripts: scripts.map { $0.toDomain() },
      interactiveOptions: (interactiveOptions ?? []).map { $0.toDomain() }
    )
  }
}

public extension ScenarioScriptDTO {
  func toDomain() -> ScenarioScript {
    ScenarioScript(
      scriptId: scriptId,
      startTimeMs: startTimeMs,
      speakerType: ScenarioSpeakerType(rawValue: speakerType),
      speakerName: speakerName,
      text: text
    )
  }
}

public extension ScenarioInteractiveOptionDTO {
  func toDomain() -> ScenarioInteractiveOption {
    ScenarioInteractiveOption(label: label, nextNodeId: nextNodeId)
  }
}
