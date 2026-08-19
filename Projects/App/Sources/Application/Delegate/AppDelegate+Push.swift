//
//  AppDelegate+Push.swift
//  Picke
//

import LogMacro
import UIKit
import UserNotifications

import Domain

extension AppDelegate {
  func configurePushNotifications() {
    let center = UNUserNotificationCenter.current()
    center.delegate = self

    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error {
        #logError("[Push] 권한 요청 실패: \(error.localizedDescription)")
        return
      }
      guard granted else {
        #logDebug("[Push] 알림 권한 거부됨")
        return
      }
      Task { @MainActor in
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  // APNs 디바이스 토큰 수신 → 저장 후 로그인 상태면 서버 등록.
  func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
    PushTokenStore.current = tokenString
    #logDebug("[Push] APNs 토큰 수신: \(tokenString.prefix(12))…")

    guard AppDependencyFactory.keychainManager.accessToken()?.isEmpty == false else { return }
    Task { await PushTokenStore.register() }
  }

  func application(
    _: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    #logError("[Push] APNs 등록 실패: \(error.localizedDescription)")
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
    PushDeeplinkBridge.handlePushPayload(userInfo)
    completionHandler()
  }
}
