//
//  AttendanceAPI.swift
//  API
//
//  Created by Picke on 10/11/26.
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
