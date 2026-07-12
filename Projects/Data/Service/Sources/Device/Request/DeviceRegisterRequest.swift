//
//  DeviceRegisterRequest.swift
//  Service
//
//  POST /api/v1/devices 요청 바디 (camelCase 도메인).
//

import Foundation

public struct DeviceRegisterRequest: Encodable {
  public let fcmToken: String
  public let platform: String

  public init(fcmToken: String, platform: String) {
    self.fcmToken = fcmToken
    self.platform = platform
  }
}
