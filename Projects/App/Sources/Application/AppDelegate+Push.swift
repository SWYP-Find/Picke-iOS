//
//  AppDelegate+Push.swift
//  Picke
//

import PickeCoreLogger
import UIKit
import UserNotifications

import DomainAssembly
import PickeStorageInterface
import ServiceAssembly

extension AppDelegate {

  // APNs 디바이스 토큰 수신 → 저장 후 로그인 상태면 서버 등록.
  func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
    PushRegistrationService.current = tokenString
    PickeLogger.debug("[Push] APNs 토큰 수신: \(tokenString.prefix(12))…", category: .app)

    Task {
      guard await NetworkContainer.authService.isLoggedIn else { return }
      let result = await Result {
        try await PushRegistrationService.register()
      }

      if case let .failure(error) = result {
        PickeLogger.error("[Push] 디바이스 등록 실패: \(error.localizedDescription)", category: .network)
      }
    }
  }

  func application(
    _: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    PickeLogger.error("[Push] APNs 등록 실패: \(error.localizedDescription)", category: .app)
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
  // 포그라운드 수신 → 배너/사운드 표시. (벨 배지는 각 화면이 /unread 로 갱신)
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent _: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound])
  }

  // 알림 탭 → 페이로드를 딥링크로 변환해 라우팅 브로드캐스트.
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    AppDeeplinkBridge.handlePushPayload(userInfo)
    completionHandler()
  }
}
