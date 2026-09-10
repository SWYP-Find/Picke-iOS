//
//  ScenarioNode.swift
//  Entity
//

import Foundation

public struct ScenarioNode: Equatable, Identifiable {
  public let nodeId: Int
  public let nodeName: String
  public let audioDuration: Int
  public let autoNextNodeId: Int?
  public let scripts: [ScenarioScript]
  public let interactiveOptions: [ScenarioInteractiveOption]

  public var id: Int { nodeId }

  public init(
    nodeId: Int,
    nodeName: String,
    audioDuration: Int,
    autoNextNodeId: Int?,
    scripts: [ScenarioScript],
    interactiveOptions: [ScenarioInteractiveOption]
  ) {
    self.nodeId = nodeId
    self.nodeName = nodeName
    self.audioDuration = audioDuration
    self.autoNextNodeId = autoNextNodeId
    self.scripts = scripts
    self.interactiveOptions = interactiveOptions
  }
}
