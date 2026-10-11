//
//  ProfileAPI.swift
//  API
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum ProfileAPI {
  case mypage
  case recap
  case creditsHistory
  case battleRecords
  case contentActivities
  case notificationSettings
  case profile

  public var description: String {
    switch self {
    case .mypage:
      return "/mypage"
    case .recap:
      return "/recap"
    case .creditsHistory:
      return "/credits/history"
    case .battleRecords:
      return "/battle-records"
    case .contentActivities:
      return "/content-activities"
    case .notificationSettings:
      return "/notification-settings"
    case .profile:
      return "/profile"
    }
  }
}
