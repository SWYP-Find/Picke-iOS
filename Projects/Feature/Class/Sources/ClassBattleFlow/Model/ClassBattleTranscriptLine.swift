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
      let hasDistinctStarts = Set(scripts.map(\.startTimeMs)).count > 1
      func revealStart(_ index: Int) -> Int {
        hasDistinctStarts
          ? scripts[index].startTimeMs
          : firstStartMs + node.audioDuration * 1000 * index / max(1, scripts.count)
      }
      for (index, script) in scripts.enumerated() {
        let startMs = revealStart(index)
        let endMs = index + 1 < scripts.count
          ? revealStart(index + 1)
          : firstStartMs + node.audioDuration * 1000
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
            + max(1, endMs - startMs) * previousCharacters / totalCharacters
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
    return transcript
  }
}
