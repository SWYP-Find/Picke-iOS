//
//  ClassAIChatMessage.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct ClassAIChatMessage: Equatable, Identifiable, Sendable {
  public enum Speaker: Equatable, Sendable {
    case opponent
    case user
  }

  public let id: UUID
  public let speaker: Speaker
  public let text: String

  public init(id: UUID = UUID(), speaker: Speaker, text: String) {
    self.id = id
    self.speaker = speaker
    self.text = text
  }
}
