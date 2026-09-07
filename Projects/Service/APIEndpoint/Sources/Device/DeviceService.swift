//
//  DeviceService.swift
//  Service
//

import Foundation

import API
import PickeNetwork

public enum DeviceService {
  /// POST /api/v1/devices
  case register(body: DeviceRegisterRequest)
  /// DELETE /api/v1/devices?fcmToken=...
  case unregister(fcmToken: String)
}

extension DeviceService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.device }

  public var path: String { "" }

  public var method: HTTPMethod {
    switch self {
    case .register:
      return .post
    case .unregister:
      return .delete
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .register(body):
      return body
    case let .unregister(fcmToken):
      return DeviceUnregisterQueryRequest(fcmToken: fcmToken)
    }
  }
}
