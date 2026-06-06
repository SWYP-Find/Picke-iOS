//
//  BattleScenario+Timeline.swift
//  Entity
//
//  시나리오 타임라인 계산.
//

import Foundation

public extension BattleScenario {
  /// 노드 시작 시간(초) = 노드 내 대사 startTimeMs 최소값.
  func nodeStartTime(for nodeId: Int) -> TimeInterval {
    guard let node = nodes.first(where: { $0.nodeId == nodeId }) else { return 0 }
    return TimeInterval(node.scripts.map(\.startTimeMs).min() ?? 0) / 1000
  }

  /// 노드 종료 시간(초) = 노드 시작 + audioDuration.
  func nodeEndTime(for node: ScenarioNode) -> TimeInterval {
    let start = TimeInterval(node.scripts.map(\.startTimeMs).min() ?? 0) / 1000
    return start + TimeInterval(node.audioDuration)
  }
}
