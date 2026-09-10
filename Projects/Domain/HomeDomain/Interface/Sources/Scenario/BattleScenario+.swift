//
//  BattleScenario+.swift
//  Entity
//

import Foundation

public extension BattleScenario {
  /// 노드 시작 시간(초) = 노드 내 대사 startTimeMs 최소값.
  func nodeStartTime(for nodeId: Int) -> TimeInterval {
    guard let node = nodes.first(where: { $0.nodeId == nodeId }) else { return 0 }
    return TimeInterval(node.scripts.map(\.startTimeMs).min() ?? 0) / 1000
  }

  /// 노드 종료 시간(초).
  func nodeEndTime(for node: ScenarioNode) -> TimeInterval {
    let nextNodeIds: [Int] = {
      if let auto = node.autoNextNodeId { return [auto] }
      return node.interactiveOptions.map(\.nextNodeId)
    }()
    let nextStarts = nextNodeIds.compactMap { id in
      nodes.first(where: { $0.nodeId == id })?.scripts.map(\.startTimeMs).min()
    }
    if let nextStart = nextStarts.min() {
      return TimeInterval(nextStart) / 1000
    }
    let start = TimeInterval(node.scripts.map(\.startTimeMs).min() ?? 0) / 1000
    return start + TimeInterval(node.audioDuration)
  }
}
