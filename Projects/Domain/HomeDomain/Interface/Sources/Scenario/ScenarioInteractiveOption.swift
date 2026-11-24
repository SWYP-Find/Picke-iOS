//
//  ScenarioInteractiveOption.swift
//  HomeDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct ScenarioInteractiveOption: Equatable, Hashable, Identifiable {
  public let optionID: Int?
  public let label: String
  public let title: String?
  public let nextNodeId: Int

  public var id: String { "\(label)-\(nextNodeId)" }

  public init(
    label: String,
    nextNodeId: Int,
    optionID: Int? = nil,
    title: String? = nil
  ) {
    self.optionID = optionID
    self.label = label
    self.title = title
    self.nextNodeId = nextNodeId
  }
}
