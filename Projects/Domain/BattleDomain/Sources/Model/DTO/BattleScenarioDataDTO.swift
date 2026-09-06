//
//  BattleScenarioDataDTO.swift
//  BattleDomain
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

  enum CodingKeys: String, CodingKey {
    case nodeId, nodeName, audioDuration, autoNextNodeId, scripts, interactiveOptions
  }

  // audioDuration 등 일부 필드가 누락/null 이어도 노드(→시나리오) 전체 디코딩이 실패하지 않도록 방어.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    nodeId = try container.decode(Int.self, forKey: .nodeId)
    nodeName = (try? container.decodeIfPresent(String.self, forKey: .nodeName)) ?? ""
    audioDuration = (try? container.decodeIfPresent(Int.self, forKey: .audioDuration)) ?? 0
    autoNextNodeId = try? container.decodeIfPresent(Int.self, forKey: .autoNextNodeId)
    scripts = (try? container.decodeIfPresent([ScenarioScriptDTO].self, forKey: .scripts)) ?? []
    interactiveOptions = try? container.decodeIfPresent(
      [ScenarioInteractiveOptionDTO].self,
      forKey: .interactiveOptions
    )
  }
}

public struct ScenarioScriptDTO: Decodable {
  public let scriptId: Int
  public let startTimeMs: Int
  public let speakerType: String
  public let speakerName: String
  public let text: String

  enum CodingKeys: String, CodingKey {
    case scriptId, startTimeMs, speakerType, speakerName, text
  }

  // startTimeMs 등 일부 필드가 누락/null 이어도 스크립트(→시나리오) 전체 디코딩이 실패하지 않도록 방어.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    scriptId = try container.decode(Int.self, forKey: .scriptId)
    startTimeMs = (try? container.decodeIfPresent(Int.self, forKey: .startTimeMs)) ?? 0
    speakerType = (try? container.decodeIfPresent(String.self, forKey: .speakerType)) ?? ""
    speakerName = (try? container.decodeIfPresent(String.self, forKey: .speakerName)) ?? ""
    text = (try? container.decodeIfPresent(String.self, forKey: .text)) ?? ""
  }
}

public struct ScenarioInteractiveOptionDTO: Decodable {
  public let label: String
  public let nextNodeId: Int
}

public typealias BattleScenarioResponseDTO = BaseResponseDTO<BattleScenarioDataDTO>
