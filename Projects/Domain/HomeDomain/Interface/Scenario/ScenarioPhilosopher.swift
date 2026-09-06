//
//  ScenarioPhilosopher.swift
//  Entity
//

import Foundation

public struct ScenarioPhilosopher: Equatable, Hashable, Identifiable {
  public let label: String
  public let name: String
  public let stance: String
  public let imageUrl: String

  public var id: String { label }

  public init(
    label: String,
    name: String,
    stance: String,
    imageUrl: String
  ) {
    self.label = label
    self.name = name
    self.stance = stance
    self.imageUrl = imageUrl
  }
}
