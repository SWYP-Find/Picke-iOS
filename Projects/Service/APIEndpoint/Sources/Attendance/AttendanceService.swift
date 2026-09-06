//
//  AttendanceService.swift
//  Service
//

import Foundation

import API
import PickeNetwork

public enum AttendanceService {
  case check
  case weekly
  case summary
}

extension AttendanceService: PickeTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .attendance }

  public var urlPath: String {
    switch self {
    case .check:
      return AttendanceAPI.check.description
    case .weekly:
      return AttendanceAPI.weekly.description
    case .summary:
      return AttendanceAPI.summary.description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .check:
      return .post
    case .weekly, .summary:
      return .get
    }
  }

  public var parameters: [String: Any]? {
    return nil
  }

  public var headers: [String: String]? {
    return APIHeader.baseHeader
  }
}
