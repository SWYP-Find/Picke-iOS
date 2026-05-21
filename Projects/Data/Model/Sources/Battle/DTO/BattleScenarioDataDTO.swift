//
//  BattleScenarioDataDTO.swift
//  Model
//

import Foundation

public struct BattleScenarioDataDTO: Decodable {
  public let battleId: Int
  public let title: String
  public let philosophers: [ScenarioPhilosopherDTO]
  public let isInteractive: Bool
  public let startNodeId: Int
  public let recommendedPathKey: String
  public let audios: [String: String]
  public let nodes: [ScenarioNodeDTO]
}

public struct ScenarioPhilosopherDTO: Decodable {
  public let label: String?
  public let name: String
  public let stance: String
  public let imageUrl: String
}

public struct ScenarioNodeDTO: Decodable {
  public let nodeId: Int
  public let nodeName: String
  public let audioDuration: Int
  public let autoNextNodeId: Int?
  public let scripts: [ScenarioScriptDTO]
  public let interactiveOptions: [ScenarioInteractiveOptionDTO]?
}

public struct ScenarioScriptDTO: Decodable {
  public let scriptId: Int
  public let startTimeMs: Int
  public let speakerType: String
  public let speakerName: String
  public let text: String
}

public struct ScenarioInteractiveOptionDTO: Decodable {
  public let label: String
  public let nextNodeId: Int
}

public typealias BattleScenarioResponseDTO = BaseResponseDTO<BattleScenarioDataDTO>
