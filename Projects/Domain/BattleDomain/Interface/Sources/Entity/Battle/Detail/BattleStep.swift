//
//  BattleStep.swift
//  Entity
//

import Foundation

public enum BattleStep: String, Equatable, Hashable, CaseIterable {
  case none = "NONE"
  case preVote = "PRE_VOTE"
  case listening = "LISTENING"
  case postVote = "POST_VOTE"
  case finished = "FINISHED"
  case completed = "COMPLETED"
  case unknown

  public init(rawValue: String) {
    self = BattleStep.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
