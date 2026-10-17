//
//  DeviceRegisterRequest.swift
//  APIEndpoint
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct DeviceRegisterRequest: Encodable, Sendable {
  public let fcmToken: String
  public let platform: String

  public init(fcmToken: String, platform: String) {
    self.fcmToken = fcmToken
    self.platform = platform
  }
}
