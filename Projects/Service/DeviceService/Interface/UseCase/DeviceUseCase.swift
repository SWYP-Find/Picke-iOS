//
//  DeviceUseCase.swift
//  DeviceServiceInterface
//

import Foundation

import Dependencies

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

extension DeviceUseCaseImpl: TestDependencyKey {
  public static let testValue = DeviceUseCaseImpl()
  public static let previewValue = DeviceUseCaseImpl()
}

public extension DependencyValues {
  var deviceUseCase: DeviceUseCaseImpl {
    get { self[DeviceUseCaseImpl.self] }
    set { self[DeviceUseCaseImpl.self] = newValue }
  }
}
