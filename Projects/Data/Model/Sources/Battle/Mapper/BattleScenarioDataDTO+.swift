//
//  BattleScenarioDataDTO+.swift
//  Model
//

import Foundation
import HomeDomainInterface

public extension BattleScenarioDataDTO {
  func toDomain() -> BattleScenario {
    BattleScenario(
      battleId: battleId,
      title: title,
      philosophers: philosophers.enumerated().map { idx, dto in
        dto.toDomain(fallbackLabel: Self.fallbackLabel(for: idx))
      },
      isInteractive: isInteractive,
      startNodeId: startNodeId,
      recommendedPathKey: RecommendedPathKey(rawValue: recommendedPathKey),
      audios: audios,
      nodes: nodes.map { $0.toDomain() }
    )
  }

  /// 응답에서 label 이 누락된 경우 사용할 인덱스 기반 폴백 (A/B/C/D…).
  private static func fallbackLabel(for index: Int) -> String {
    guard let scalar = Unicode.Scalar(0x41 + index) else { return "" }
    return String(Character(scalar))
  }
}

public extension ScenarioPhilosopherDTO {
  func toDomain(fallbackLabel: String) -> ScenarioPhilosopher {
    ScenarioPhilosopher(
      label: label ?? fallbackLabel,
      name: name,
      stance: stance,
      imageUrl: imageUrl
    )
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
