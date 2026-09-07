//
//  DeviceUnregisterQueryRequest.swift
//  APIEndpoint
//

import Foundation

public struct DeviceUnregisterQueryRequest: Encodable, Sendable {
  public let fcmToken: String

  public init(fcmToken: String) {
    self.fcmToken = fcmToken
  }
}
