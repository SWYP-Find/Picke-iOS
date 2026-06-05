//
//  BattleScenario+Chat.swift
//  Entity
//
//  채팅방에서 쓰는 시나리오 → 화면 도메인 계산 (노드 가시성/시간, 발화자 매핑).
//  currentTime 같은 UI 상태에 무관한 순수 도메인 로직만 둔다.
//

import Foundation

public extension BattleScenario {
  /// 화면에 노출할 노드들. `visibleNodeIds` 우선, 비어있으면 현재/시작 노드 폴백.
  func chatVisibleNodes(visibleNodeIds: [Int], currentNodeId: Int?) -> [ScenarioNode] {
    let ids = visibleNodeIds.isEmpty ? [currentNodeId ?? startNodeId] : visibleNodeIds
    return ids.compactMap { id in nodes.first { $0.nodeId == id } }
  }

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

  /// 대사(script) → 화면 발화자(ChatSpeaker) 매핑.
  func chatSpeaker(for script: ScenarioScript) -> ChatSpeaker {
    switch script.speakerType {
    case .a:
      return chatSpeaker(label: "A", side: .left, fallbackName: script.speakerName)
    case .b:
      return chatSpeaker(label: "B", side: .right, fallbackName: script.speakerName)
    case .narrator:
      return ChatSpeaker(name: script.speakerName, side: .center)
    case .philosopher, .unknown:
      if let philosopher = philosophers.first(where: { $0.name == script.speakerName }) {
        let side: ChatSpeakerSide = philosopher.label == "B" ? .right : .left
        return ChatSpeaker(
          label: philosopher.label,
          name: philosopher.name,
          imageURL: philosopher.imageUrl,
          side: side
        )
      }
      return ChatSpeaker(name: script.speakerName, side: .center)
    }
  }

  private func chatSpeaker(
    label: String,
    side: ChatSpeakerSide,
    fallbackName: String
  ) -> ChatSpeaker {
    guard let philosopher = philosophers.first(where: { $0.label == label }) else {
      return ChatSpeaker(label: label, name: fallbackName, side: side)
    }
    return ChatSpeaker(
      label: philosopher.label,
      name: philosopher.name,
      imageURL: philosopher.imageUrl,
      side: side
    )
  }
}
