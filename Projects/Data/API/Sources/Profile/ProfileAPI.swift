//
//  ProfileAPI.swift
//  API
//

import Foundation

public enum ProfileAPI {
  case mypage
  case creditsHistory
  case battleRecords
  case contentActivities

  public var description: String {
    switch self {
    case .mypage:
      return "mypage"
    case .creditsHistory:
      return "credits/history"
    case .battleRecords:
      return "battle-records"
    case .contentActivities:
      return "content-activities"
    }
  }
}
