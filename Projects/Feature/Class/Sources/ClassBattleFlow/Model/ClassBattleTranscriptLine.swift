import Foundation
import HomeDomainInterface
import PickeCoreUtility

public struct ClassBattleTranscriptLine: Equatable, Identifiable, Sendable {
  public let id: Int
  public let startTime: Double
  public let speakerName: String
  public let speakerImageURL: String?
  public let text: String
  public let side: String

  public init(
    id: Int,
    startTime: Double,
    speakerName: String,
    speakerImageURL: String?,
    text: String,
    side: String
  ) {
    self.id = id
    self.startTime = startTime
    self.speakerName = speakerName
    self.speakerImageURL = speakerImageURL
    self.text = text
    self.side = side
  }
}

public extension ClassBattleTranscriptLine {
  static func from(scenario: BattleScenario) -> [ClassBattleTranscriptLine] {
    var transcript: [ClassBattleTranscriptLine] = []
    var visibleNodeID = scenario.startNodeId
    var visitedNodeIDs = Set<Int>()
    while !visitedNodeIDs.contains(visibleNodeID) {
      guard let node = scenario.nodes.first(where: { $0.nodeId == visibleNodeID }) else { break }
      visitedNodeIDs.insert(visibleNodeID)
      let scripts = node.scripts
      let firstStartMs = scripts.map(\.startTimeMs).min() ?? 0
      let nodeEndMs = nextVisibleStartMs(after: node, in: scenario)
        ?? Int((scenario.nodeEndTime(for: node) * 1000).rounded())
      let boundaryMs = max(nodeEndMs, scripts.map(\.startTimeMs).max() ?? firstStartMs)
      let hasDistinctStarts = Set(scripts.map(\.startTimeMs)).count > 1
      func revealStart(_ index: Int) -> Int {
        hasDistinctStarts
          ? scripts[index].startTimeMs
          : firstStartMs + (boundaryMs - firstStartMs) * index / max(1, scripts.count)
      }
      for (index, script) in scripts.enumerated() {
        let startMs = revealStart(index)
        let endMs = index + 1 < scripts.count
          ? max(startMs, min(boundaryMs, revealStart(index + 1)))
          : boundaryMs
        let side: String
        switch script.speakerType {
        case .a: side = "A"
        case .b: side = "B"
        case .narrator: side = "NARRATOR"
        case .philosopher, .unknown:
          side = scenario.philosophers.first(where: { $0.name == script.speakerName })?.label ?? "NARRATOR"
        }
        let philosopher = scenario.philosophers.first(where: { $0.label == side })
        let speakerName = philosopher?.name ?? script.speakerName
        let sentences = script.text.splitIntoSentences()
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty }
        let parts = sentences.isEmpty ? [script.text] : sentences
        let totalCharacters = max(1, parts.reduce(0) { $0 + $1.count })
        var previousCharacters = 0
        for sentence in parts {
          let sentenceStartMs = startMs
            + max(0, endMs - startMs) * previousCharacters / totalCharacters
          previousCharacters += sentence.count
          transcript.append(ClassBattleTranscriptLine(
            id: transcript.count,
            startTime: Double(sentenceStartMs) / 1000,
            speakerName: speakerName,
            speakerImageURL: philosopher?.imageUrl,
            text: sentence,
            side: side
          ))
        }
      }
      guard let nextNodeID = scenario.nextNodeId(for: node) else { break }
      visibleNodeID = nextNodeID
    }
    return transcript.sorted {
      $0.startTime == $1.startTime ? $0.id < $1.id : $0.startTime < $1.startTime
    }
    .enumerated()
    .map { index, line in
      ClassBattleTranscriptLine(
        id: index,
        startTime: line.startTime,
        speakerName: line.speakerName,
        speakerImageURL: line.speakerImageURL,
        text: line.text,
        side: line.side
      )
    }
  }

  private static func nextVisibleStartMs(
    after node: ScenarioNode,
    in scenario: BattleScenario
  ) -> Int? {
    var nextNodeID = scenario.nextNodeId(for: node)
    var visitedNodeIDs = Set<Int>()
    while let id = nextNodeID, visitedNodeIDs.insert(id).inserted {
      guard let nextNode = scenario.nodes.first(where: { $0.nodeId == id }) else { break }
      if let startMs = nextNode.scripts.map(\.startTimeMs).min() { return startMs }
      nextNodeID = scenario.nextNodeId(for: nextNode)
    }
    return nil
  }
}
