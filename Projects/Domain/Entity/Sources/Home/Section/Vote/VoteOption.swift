//
//  VoteOption.swift
//  Entity
//

import Foundation

public struct VoteOption: Equatable, Identifiable, Hashable {
  public let label: String
  public let title: String

  public var id: String { label }

  public init(
    label: String,
    title: String
  ) {
    self.label = label
    self.title = title
  }
}
