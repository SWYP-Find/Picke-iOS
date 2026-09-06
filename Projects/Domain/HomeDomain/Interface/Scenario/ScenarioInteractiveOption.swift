//
//  ScenarioInteractiveOption.swift
//  Entity
//

import Foundation

public struct ScenarioInteractiveOption: Equatable, Hashable, Identifiable {
  public let label: String
  public let nextNodeId: Int

  public var id: String { "\(label)-\(nextNodeId)" }

  public init(
    label: String,
    nextNodeId: Int
  ) {
    self.label = label
    self.nextNodeId = nextNodeId
  }
}
