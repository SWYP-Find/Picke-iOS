//
//  BattleScenario+.swift
//  Entity
//

import Foundation

public extension BattleScenario {
  /// 비대화형 콘텐츠는 연결 ID가 생략되어도 응답 순서대로 재생된다.
  func nextNodeId(for node: ScenarioNode) -> Int? {
    if let nextNodeId = node.autoNextNodeId { return nextNodeId }
    guard !isInteractive,
          node.interactiveOptions.isEmpty,
          let index = nodes.firstIndex(where: { $0.nodeId == node.nodeId }),
          nodes.indices.contains(index + 1)
    else { return nil }
    return nodes[index + 1].nodeId
  }

  /// 노드 시작 시간(초) = 노드 내 대사 startTimeMs 최소값.
  func nodeStartTime(for nodeId: Int) -> TimeInterval {
    guard let node = nodes.first(where: { $0.nodeId == nodeId }) else { return 0 }
    return TimeInterval(node.scripts.map(\.startTimeMs).min() ?? 0) / 1000
  }

  /// 노드 종료 시간(초).
  func nodeEndTime(for node: ScenarioNode) -> TimeInterval {
    let nextNodeIds: [Int] = {
      if let next = nextNodeId(for: node) { return [next] }
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
