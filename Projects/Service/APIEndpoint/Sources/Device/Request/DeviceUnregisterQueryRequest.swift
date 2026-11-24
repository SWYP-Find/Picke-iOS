//
//  DeviceUnregisterQueryRequest.swift
//  APIEndpoint
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct DeviceUnregisterQueryRequest: Encodable, Sendable {
  public let fcmToken: String

  public init(fcmToken: String) {
    self.fcmToken = fcmToken
  }
}
