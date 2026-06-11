//
//  DeviceRepositoryImpl.swift
//  Repository
//
//  FCM 디바이스 토큰 등록/해제 — POST/DELETE /api/v1/devices.
//

import Foundation

import DomainInterface
import Entity
import Model
import Service

import LogMacro
import Moya

@preconcurrency import AsyncMoya

public final class DeviceRepositoryImpl: DeviceInterface, @unchecked Sendable {
  private let provider: MoyaProvider<DeviceService>

  public init(
    provider: MoyaProvider<DeviceService> = MoyaProvider<DeviceService>.authorized
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
