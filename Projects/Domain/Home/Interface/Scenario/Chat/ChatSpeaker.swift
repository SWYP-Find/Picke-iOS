//
//  ChatSpeaker.swift
//  Entity
//

import Foundation

public struct ChatSpeaker: Equatable, Identifiable, Hashable {
  public let label: String?
  public let name: String
  public let imageURL: String?
  public let side: ChatSpeakerSide

  public var id: String { "\(label ?? name)-\(side)" }

  public init(
    label: String? = nil,
    name: String,
    imageURL: String? = nil,
    side: ChatSpeakerSide
  ) {
    self.label = label
    self.name = name
    self.imageURL = imageURL
    self.side = side
  }
}
