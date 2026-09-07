//
//  ShareActionData.swift
//  UseCase
//

import Foundation

public enum ShareTarget: String, Sendable {
  case recap
  case battle
  case finalVote = "final_vote"
}

public struct ShareActionData: Sendable {
  public let target: ShareTarget
  public let channel: String?

  public init(target: ShareTarget, channel: String? = nil) {
    self.target = target
    self.channel = channel
  }
}
