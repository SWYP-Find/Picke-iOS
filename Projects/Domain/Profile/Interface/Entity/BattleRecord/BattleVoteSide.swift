//
//  BattleVoteSide.swift
//  Entity
//

import Foundation

/// 투표 진영 (PRO=찬성 / CON=반대).
public enum BattleVoteSide: String, Equatable {
  case pro = "PRO"
  case con = "CON"
  case unknown = ""

  public init(rawValue: String) {
    switch rawValue.uppercased() {
    case "PRO": self = .pro
    case "CON": self = .con
    default: self = .unknown
    }
  }
}
