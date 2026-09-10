//
//  PushRegistrationServiceTests.swift
//  PickeTests
//

import ComposableArchitecture
import DeviceServiceInterface
import PickeStorageInterface
import Testing

@testable import Picke

@Suite("PushRegistrationService", .serialized)
struct PushRegistrationServiceTests {
  @Test
  func 토큰이_없으면_등록하지_않고_false를_반환한다() async throws {
    try await withDependencies {
      $0.context = .test
    } operation: {
      DeviceTokenStorage.token = nil
      let useCase = FakeDeviceUseCase()

      let registered = try await PushRegistrationService.register(deviceUseCase: useCase)

      #expect(registered == false)
      #expect(await useCase.registeredTokens.isEmpty)
    }
  }

  @Test
  func 토큰이_있으면_ios_플랫폼으로_등록하고_true를_반환한다() async throws {
    try await withDependencies {
      $0.context = .test
    } operation: {
      DeviceTokenStorage.token = "apns-token"
      defer { DeviceTokenStorage.token = nil }
      let useCase = FakeDeviceUseCase()

      let registered = try await PushRegistrationService.register(deviceUseCase: useCase)

      #expect(registered == true)
      #expect(await useCase.registeredTokens == ["apns-token"])
      #expect(await useCase.registeredPlatforms == [.ios])
    }
  }

  @Test
  func 등록_실패는_호출자에게_throw된다() async {
    await withDependencies {
      $0.context = .test
    } operation: {
      DeviceTokenStorage.token = "apns-token"
      defer { DeviceTokenStorage.token = nil }
      let useCase = FakeDeviceUseCase(registerError: RegistrationError.failed)

      await #expect(throws: RegistrationError.failed) {
        try await PushRegistrationService.register(deviceUseCase: useCase)
      }
    }
  }
}

private actor FakeDeviceUseCase: DeviceInterface {
  private(set) var registeredTokens: [String] = []
  private(set) var registeredPlatforms: [DevicePlatform] = []
  private let registerError: RegistrationError?

  init(registerError: RegistrationError? = nil) {
    self.registerError = registerError
  }

  func registerDevice(
    fcmToken: String,
    platform: DevicePlatform
  ) async throws {
    if let registerError {
      throw registerError
    }
    registeredTokens.append(fcmToken)
    registeredPlatforms.append(platform)
  }

  func unregisterDevice(fcmToken _: String) async throws {}
}

private enum RegistrationError: Error, Equatable {
  case failed
}
