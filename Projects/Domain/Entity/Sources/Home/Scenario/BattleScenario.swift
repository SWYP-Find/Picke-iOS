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
