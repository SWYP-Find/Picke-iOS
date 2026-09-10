//
//  PushRegistrationService.swift
//  Picke
//

import Foundation

import DeviceServiceInterface
import PickeCoreLogger
import PickeStorageInterface

enum PushRegistrationService {
  static var current: String? {
    get { DeviceTokenStorage.token }
    set { DeviceTokenStorage.token = newValue }
  }

  /// 로그인 직후 / 토큰 갱신 시 디바이스 등록.
  @discardableResult
  static func register(deviceUseCase: any DeviceInterface = DeviceUseCaseImpl()) async throws -> Bool {
    guard let token = current, !token.isEmpty else { return false }
    try await deviceUseCase.registerDevice(fcmToken: token, platform: .ios)
    PickeLogger.debug("[Push] 디바이스 등록 완료", category: .network)
    return true
  }
}
