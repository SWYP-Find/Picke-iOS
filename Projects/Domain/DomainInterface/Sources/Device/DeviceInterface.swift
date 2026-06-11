//
//  DeviceInterface.swift
//  DomainInterface
//
//  FCM 디바이스 토큰 등록/해제 Repository 인터페이스.
//

import Entity
import Foundation
import WeaveDI

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

public struct DeviceRepositoryDependency: DependencyKey {
  public static var liveValue: DeviceInterface {
    UnifiedDI.resolve(DeviceInterface.self) ?? DefaultDeviceRepositoryImpl()
  }

  public static var testValue: DeviceInterface {
    UnifiedDI.resolve(DeviceInterface.self) ?? DefaultDeviceRepositoryImpl()
  }

  public static var previewValue: DeviceInterface = liveValue
}

public extension DependencyValues {
  var deviceRepository: DeviceInterface {
    get { self[DeviceRepositoryDependency.self] }
    set { self[DeviceRepositoryDependency.self] = newValue }
  }
}
