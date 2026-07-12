//
//  ScenarioSpeakerType.swift
//  Entity
//

import Foundation

public enum ScenarioSpeakerType: String, Equatable, Hashable, CaseIterable {
  case a = "A"
  case b = "B"
  case narrator = "NARRATOR"
  case philosopher = "PHILOSOPHER"
  case unknown

  public init(rawValue: String) {
    self = ScenarioSpeakerType.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
