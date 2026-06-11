//
//  PushTokenStore.swift
//  Picke
//
//  APNs 디바이스 토큰 보관 + 서버 등록/해제 헬퍼. (FCM 미사용)
//  - current: 마지막으로 발급받은 APNs 토큰 (UserDefaults 캐시).
//  - register/unregister: POST/DELETE /api/v1/devices (DeviceUseCase 경유).
//  로그아웃 해제는 Keychain 초기화 전에 호출해야 인증 헤더가 살아있다.
//

import Foundation

import Entity
import LogMacro
import UseCase

enum PushTokenStore {
  static var current: String? {
    get { DeviceTokenStorage.token }
    set { DeviceTokenStorage.token = newValue }
  }

  /// 로그인 직후 / 토큰 갱신 시 디바이스 등록.
  static func register() async {
    guard let token = current, !token.isEmpty else { return }
    do {
      try await DeviceUseCaseImpl().registerDevice(fcmToken: token, platform: .ios)
      #logDebug("[Push] 디바이스 등록 완료")
    } catch {
      #logError("[Push] 디바이스 등록 실패: \(error.localizedDescription)")
    }
  }

  /// 로그아웃 / 탈퇴 시 디바이스 해제 (Keychain 초기화 전에 호출).
  static func unregister() async {
    guard let token = current, !token.isEmpty else { return }
    do {
      try await DeviceUseCaseImpl().unregisterDevice(fcmToken: token)
      #logDebug("[Push] 디바이스 해제 완료")
    } catch {
      #logError("[Push] 디바이스 해제 실패: \(error.localizedDescription)")
    }
  }
}
