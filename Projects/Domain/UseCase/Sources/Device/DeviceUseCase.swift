//
//  DeviceUseCase.swift
//  UseCase
//

import Foundation

import DomainInterface
import Entity

import ComposableArchitecture

/// APNs 디바이스 토큰 보관소 (UserDefaults). App(수신)·Presentation(로그아웃 해제) 공용.
public enum DeviceTokenStorage {
  private static let key = "PickeDeviceToken"

  public static var token: String? {
    get { UserDefaults.standard.string(forKey: key) }
    set { UserDefaults.standard.set(newValue, forKey: key) }
  }
}

public struct DeviceUseCaseImpl: DeviceInterface {
  @Dependency(\.deviceRepository) private var deviceRepository

  public init() {}

  public func registerDevice(fcmToken: String, platform: DevicePlatform) async throws {
    try await deviceRepository.registerDevice(fcmToken: fcmToken, platform: platform)
  }

  public func unregisterDevice(fcmToken: String) async throws {
    try await deviceRepository.unregisterDevice(fcmToken: fcmToken)
  }
}

extension DeviceUseCaseImpl: DependencyKey {
  public static var liveValue = DeviceUseCaseImpl()
  public static var testValue = DeviceUseCaseImpl()
  public static var previewValue = DeviceUseCaseImpl()
}

public extension DependencyValues {
  var deviceUseCase: DeviceUseCaseImpl {
    get { self[DeviceUseCaseImpl.self] }
    set { self[DeviceUseCaseImpl.self] = newValue }
  }
}
