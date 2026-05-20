//
//  BattleScenario.swift
//  Entity
//
//  `GET /api/v1/battles/{battleId}/scenario` 응답 도메인 모델.
//

import Foundation

public struct BattleScenario: Equatable, Identifiable {
  public let battleId: Int
  public let title: String
  public let philosophers: [ScenarioPhilosopher]
  public let isInteractive: Bool
  public let startNodeId: Int
  public let recommendedPathKey: RecommendedPathKey
  public let audios: [String: String]
  public let nodes: [ScenarioNode]

  public var id: Int { battleId }

  public init(
    battleId: Int,
    title: String,
    philosophers: [ScenarioPhilosopher],
    isInteractive: Bool,
    startNodeId: Int,
    recommendedPathKey: RecommendedPathKey,
    audios: [String: String],
    nodes: [ScenarioNode]
  ) {
    self.battleId = battleId
    self.title = title
    self.philosophers = philosophers
    self.isInteractive = isInteractive
    self.startNodeId = startNodeId
    self.recommendedPathKey = recommendedPathKey
    self.audios = audios
    self.nodes = nodes
  }
}

public struct ScenarioPhilosopher: Equatable, Hashable, Identifiable {
  public let label: String
  public let name: String
  public let stance: String
  public let imageUrl: String

  public var id: String { label }

  public init(label: String, name: String, stance: String, imageUrl: String) {
    self.label = label
    self.name = name
    self.stance = stance
    self.imageUrl = imageUrl
  }
}

public struct ScenarioNode: Equatable, Identifiable {
  public let nodeId: Int
  public let nodeName: String
  public let audioDuration: Int
  public let autoNextNodeId: Int?
  public let scripts: [ScenarioScript]
  public let interactiveOptions: [ScenarioInteractiveOption]

  public var id: Int { nodeId }

  public init(
    nodeId: Int,
    nodeName: String,
    audioDuration: Int,
    autoNextNodeId: Int?,
    scripts: [ScenarioScript],
    interactiveOptions: [ScenarioInteractiveOption]
  ) {
    self.nodeId = nodeId
    self.nodeName = nodeName
    self.audioDuration = audioDuration
    self.autoNextNodeId = autoNextNodeId
    self.scripts = scripts
    self.interactiveOptions = interactiveOptions
  }
}

public struct ScenarioScript: Equatable, Identifiable, Hashable {
  public let scriptId: Int
  public let startTimeMs: Int
  public let speakerType: ScenarioSpeakerType
  public let speakerName: String
  public let text: String

  public var id: Int { scriptId }

  public init(
    scriptId: Int,
    startTimeMs: Int,
    speakerType: ScenarioSpeakerType,
    speakerName: String,
    text: String
  ) {
    self.scriptId = scriptId
    self.startTimeMs = startTimeMs
    self.speakerType = speakerType
    self.speakerName = speakerName
    self.text = text
  }
}

public struct ScenarioInteractiveOption: Equatable, Hashable, Identifiable {
  public let label: String
  public let nextNodeId: Int

  public var id: String { "\(label)-\(nextNodeId)" }

  public init(label: String, nextNodeId: Int) {
    self.label = label
    self.nextNodeId = nextNodeId
  }
}

public enum ScenarioSpeakerType: String, Equatable, Hashable, CaseIterable {
  case narrator = "NARRATOR"
  case philosopher = "PHILOSOPHER"
  case unknown

  public init(rawValue: String) {
    self = ScenarioSpeakerType.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}

public enum RecommendedPathKey: String, Equatable, Hashable, CaseIterable {
  case common = "COMMON"
  case unknown

  public init(rawValue: String) {
    self = RecommendedPathKey.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
