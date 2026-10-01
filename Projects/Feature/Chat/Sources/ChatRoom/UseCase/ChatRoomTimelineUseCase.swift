import Foundation
import HomeDomainInterface
import PickeCoreUtility

/// 시나리오와 재생 시각에서 화면에 표시할 메시지를 계산한다.
struct ChatRoomTimelineUseCase {
  func messages(
    scenario: BattleScenario,
    visibleNodeIds: [Int],
    currentNodeId: Int?,
    currentTime: TimeInterval
  ) -> [ChatMessage] {
    let nodes = visibleNodes(
      in: scenario,
      visibleNodeIds: visibleNodeIds,
      currentNodeId: currentNodeId
    )
    let currentMs = Int(currentTime * 1000)
    return nodes.flatMap { messages(for: $0, in: scenario, currentMs: currentMs) }
  }

  private func messages(
    for node: ScenarioNode,
    in scenario: BattleScenario,
    currentMs: Int
  ) -> [ChatMessage] {
    let scripts = node.scripts
    // 대사별 startTimeMs 가 구분되면 그 값을, 모두 같거나(0) 평평하면 노드 오디오 구간에 균등 분배.
    let distinctStarts = Set(scripts.map(\.startTimeMs)).count
    let nodeStartMs = scripts.map(\.startTimeMs).min() ?? 0
    let nodeDurationMs = node.audioDuration * 1000
    let count = scripts.count

    func revealStart(_ index: Int) -> Int {
      if distinctStarts > 1 {
        return scripts[index].startTimeMs
      }
      if count > 1 {
        return nodeStartMs + nodeDurationMs * index / count
      }
      return nodeStartMs
    }

    return scripts.enumerated().flatMap { index, script -> [ChatMessage] in
      let scriptStart = revealStart(index)
      guard currentMs >= scriptStart else { return [] }
      let scriptEnd = index + 1 < count ? revealStart(index + 1) : nodeStartMs + nodeDurationMs
      let windowMs = max(1, scriptEnd - scriptStart)
      let messageSpeaker = speaker(for: script, in: scenario)

      // 나레이션/클로징(center)·발언자(좌/우) 모두 문장마다 개별 말풍선.
      // 문장 시작 시점은 글자수 비례로 분배(긴 문장=더 긴 시간) → 싱크.
      let sentences = script.text.splitIntoSentences()
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
      guard sentences.count > 1 else {
        return [ChatMessage(
          messageId: UUID.deterministic(script.scriptId, 0),
          speaker: messageSpeaker,
          text: script.text,
          startTimeMs: scriptStart
        )]
      }
      let totalChars = max(1, sentences.reduce(0) { $0 + $1.count })
      var charsBefore = 0
      var result: [ChatMessage] = []
      for (sentenceIndex, sentence) in sentences.enumerated() {
        let sentenceStart = scriptStart + windowMs * charsBefore / totalChars
        charsBefore += sentence.count
        guard currentMs >= sentenceStart else { break }
        result.append(ChatMessage(
          messageId: UUID.deterministic(script.scriptId, sentenceIndex),
          speaker: messageSpeaker,
          text: sentence,
          startTimeMs: sentenceStart
        ))
      }
      return result
    }
  }

  private func visibleNodes(
    in scenario: BattleScenario,
    visibleNodeIds: [Int],
    currentNodeId: Int?
  ) -> [ScenarioNode] {
    let ids = visibleNodeIds.isEmpty ? [currentNodeId ?? scenario.startNodeId] : visibleNodeIds
    return ids.compactMap { id in
      scenario.nodes.first { $0.nodeId == id }
    }
  }

  private func speaker(
    for script: ScenarioScript,
    in scenario: BattleScenario
  ) -> ChatSpeaker {
    switch script.speakerType {
    case .a:
      return speaker(
        label: "A",
        side: .left,
        fallbackName: script.speakerName,
        in: scenario
      )
    case .b:
      return speaker(
        label: "B",
        side: .right,
        fallbackName: script.speakerName,
        in: scenario
      )
    case .narrator:
      return ChatSpeaker(name: script.speakerName, side: .center)
    case .philosopher, .unknown:
      if let philosopher = scenario.philosophers.first(where: { $0.name == script.speakerName }) {
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

  private func speaker(
    label: String,
    side: ChatSpeakerSide,
    fallbackName: String,
    in scenario: BattleScenario
  ) -> ChatSpeaker {
    guard let philosopher = scenario.philosophers.first(where: { $0.label == label }) else {
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
