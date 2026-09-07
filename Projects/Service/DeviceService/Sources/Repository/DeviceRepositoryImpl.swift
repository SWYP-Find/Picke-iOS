//
//  DeviceRepositoryImpl.swift
//  DeviceService
//

import Foundation

import Dependencies

import APIEndpoint
import PickeNetwork

import DeviceServiceInterface

public final class DeviceRepositoryImpl: DeviceInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func registerDevice(fcmToken: String, platform: DevicePlatform) async throws {
    _ = try await client.send(
      DeviceService.register( body: DeviceRegisterRequest( fcmToken: fcmToken, platform: platform.rawValue ) ),
      as: PickeEmptyResponse.self
    )
  }

  public func unregisterDevice(fcmToken: String) async throws {
    _ = try await client.send(
      DeviceService.unregister(fcmToken: fcmToken),
      as: PickeEmptyResponse.self
    )
  }
}
