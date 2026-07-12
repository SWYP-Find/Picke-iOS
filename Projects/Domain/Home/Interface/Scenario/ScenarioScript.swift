//
//  ScenarioScript.swift
//  Entity
//

import Foundation

public struct ScenarioScript: Equatable, Identifiable, Hashable {
  public let scriptId: Int
  public let startTimeMs: Int
  public let speakerType: ScenarioSpeakerType
  public let speakerName: String
  public let text: String

  public var id: Int { scriptId }

  public init(
    scriptId: Int,
    startTimeMs: Int,
    speakerType: ScenarioSpeakerType,
    speakerName: String,
    text: String
  ) {
    self.scriptId = scriptId
    self.startTimeMs = startTimeMs
    self.speakerType = speakerType
    self.speakerName = speakerName
    self.text = text
  }
}
