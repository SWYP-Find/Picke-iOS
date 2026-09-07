//
//  AttendanceService.swift
//  Service
//

import Foundation

import Alamofire
import API
import PickeNetwork

public enum AttendanceService {
  case check
  case weekly
  case summary
}

extension AttendanceService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.attendance }

  public var path: String {
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
}
