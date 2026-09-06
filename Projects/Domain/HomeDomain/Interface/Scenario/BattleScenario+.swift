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
  /// 다음 노드(autoNext 또는 인터랙티브 분기)의 시작 시각이 실제 오디오 경계이므로 우선 사용한다.
  /// (audioDuration 합산은 실제 오디오와 어긋나, 선택지가 마지막 대사 도중에 떠 음성이 끊기는 문제가 있음)
  /// 다음 노드가 없으면(클로징) 노드 시작 + audioDuration.
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
