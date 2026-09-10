//
//  DeviceInterface.swift
//  DeviceServiceInterface
//

import Dependencies
import Foundation

public protocol DeviceInterface: Sendable {
  /// 로그인 직후 / 토큰 갱신 시 FCM 토큰 등록.
  func registerDevice(fcmToken: String, platform: DevicePlatform) async throws
  /// 로그아웃 시 FCM 토큰 해제 (idempotent).
  func unregisterDevice(fcmToken: String) async throws
}

public struct DefaultDeviceRepositoryImpl: DeviceInterface {
  public init() {}
  public func registerDevice(fcmToken _: String, platform _: DevicePlatform) async throws {}
  public func unregisterDevice(fcmToken _: String) async throws {}
}

/// live 구현(`DeviceRepositoryImpl`)은 DeviceService 가 `DependencyKey` 로 이어 붙인다.
public struct DeviceRepositoryDependency: TestDependencyKey {
  public static var testValue: DeviceInterface { DefaultDeviceRepositoryImpl() }
}

public extension DependencyValues {
  var deviceRepository: DeviceInterface {
    get { self[DeviceRepositoryDependency.self] }
    set { self[DeviceRepositoryDependency.self] = newValue }
  }
}
