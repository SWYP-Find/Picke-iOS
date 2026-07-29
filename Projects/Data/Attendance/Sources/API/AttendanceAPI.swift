//
//  AttendanceAPI.swift
//  API
//

import Foundation

public enum AttendanceAPI {
  case check
  case weekly
  case summary

  public var description: String {
    switch self {
    case .check:
      return "/check"
    case .weekly:
      return "/weekly"
    case .summary:
      return "/summary"
    }
  }
}
