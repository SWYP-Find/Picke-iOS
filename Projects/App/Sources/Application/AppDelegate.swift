import Firebase
import GoogleMobileAds
import LogMacro
import Mixpanel
import MixpanelSessionReplay
import UIKit
import UserNotifications
import WeaveDI

import DomainInterface

class AppDelegate: UIResponder, UIApplicationDelegate {
  let mixPanelKey = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_TOKEN") as? String

  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    #logDebug(
      "Mixpanel initialize",
      [
        "token_exists": !(mixPanelKey?.isEmpty ?? true),
        "token_prefix": String((mixPanelKey ?? "").prefix(6)),
      ]
    )
    Mixpanel.initialize(token: mixPanelKey ?? "", trackAutomaticEvents: true)
    // NOTE: MixpanelSessionReplay 1.4.0의 _UIReparentingView swizzling이
    // SwiftUI UIHostingController.view에 적용되며 콘솔 경고가 출력될 수 있음 (기능 영향 없음).
    // SDK 측 SwiftUI 호환성 개선 시 경고 자동 해소 예정.
    initializeMixpanelSessionReplay()
    MobileAds.shared.start()

    // 🔔 푸시 알림(APNs) 초기화
    configurePushNotifications()

    // DI 관리자 초기화
    WeaveDI.Container.bootstrapInTask { @DIContainerActor _ in
      await AppDIManager.shared.registerDefaultDependencies()

      // Kingfisher 글로벌 requestModifier 등록 — DI 등록 직후라 KeychainManaging resolve 보장
      if let keychainManager = UnifiedDI.resolve(KeychainManaging.self) {
        await MainActor.run {
          KingfisherConfigurator.configureAuthorizedDownloader(
            keychainManager: keychainManager
          )
        }
      }
    }

    return true
  }

  func application(
    _: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(
    _: UIApplication,
    didDiscardSceneSessions _: Set<UISceneSession>
  ) {}

  // MARK: - Push Notifications (APNs)

  private func configurePushNotifications() {
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

    guard let keychainManager = UnifiedDI.resolve(KeychainManaging.self),
          keychainManager.accessToken()?.isEmpty == false else { return }
    Task { await PushTokenStore.register() }
  }

  func application(
    _: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    #logError("[Push] APNs 등록 실패: \(error.localizedDescription)")
  }

  // MARK: - Image Caching Configuration

  private func initializeMixpanelSessionReplay() {
    guard !(mixPanelKey?.isEmpty ?? true) else { return }

    var config = MPSessionReplayConfig(wifiOnly: false)
    config.enableSessionReplayOniOS26AndLater = true

    MPSessionReplay.initialize(
      token: Mixpanel.mainInstance().apiToken,
      distinctId: Mixpanel.mainInstance().distinctId,
      config: config
    )
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
  // 포그라운드 수신 → 배너/사운드 표시.
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
