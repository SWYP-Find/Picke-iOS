//
//  AttendanceAPI.swift
//  API
//
//  출석체크 엔드포인트 경로 조각. 도메인 prefix(api/v1/attendance)는 PieckeDomain 이 붙인다.
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
