//
//  DeviceRepositoryImpl.swift
//  DeviceService
//

import Foundation

import APIEndpoint
import PickeNetwork

import DeviceServiceInterface
import LogMacro

public final class DeviceRepositoryImpl: DeviceInterface, @unchecked Sendable {
  private let provider: any NetworkProviding<DeviceService>

  public init(
    provider: any NetworkProviding<DeviceService> = AlamofireNetworkProvider<DeviceService>.authorized
  ) {
    self.provider = provider
  }

  public func registerDevice(fcmToken: String, platform: DevicePlatform) async throws {
    let _: BaseResponseDTO<String> = try await provider.request(
      .register(
        body: DeviceRegisterRequest(
          fcmToken: fcmToken,
          platform: platform.rawValue
        )
      )
    )
  }

  public func unregisterDevice(fcmToken: String) async throws {
    let _: BaseResponseDTO<String> = try await provider.request(
      .unregister(fcmToken: fcmToken)
    )
  }
}
