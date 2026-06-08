//
//  ProfileAPI.swift
//  API
//

import Foundation

public enum ProfileAPI {
  case mypage
  case creditsHistory
  case battleRecords

  public var description: String {
    switch self {
    case .mypage:
      return "mypage"
    case .creditsHistory:
      return "credits/history"
    case .battleRecords:
      return "battle-records"
    }
  }
}
