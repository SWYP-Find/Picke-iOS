import Firebase
import GoogleMobileAds
import LogMacro
import Mixpanel
import MixpanelSessionReplay
import Sentry
import UIKit
import UserNotifications
import WeaveDI

import Domain

class AppDelegate: UIResponder, UIApplicationDelegate {
  let mixPanelKey = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_TOKEN") as? String

  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureSentry()
    FirebaseApp.configure()
    #logDebug(
      "Mixpanel initialize",
      [
        "token_exists": !(mixPanelKey?.isEmpty ?? true),
        "token_prefix": String((mixPanelKey ?? "").prefix(6)),
      ]
    )
    Mixpanel.initialize(token: mixPanelKey ?? "", trackAutomaticEvents: true)
    // 모든 이벤트에 자동 첨부되는 공통 슈퍼 프로퍼티(플랫폼/버전). is_logged_in 은 로그인/로그아웃이 관리.
    let info = Bundle.main.infoDictionary
    Mixpanel.mainInstance().registerSuperProperties([
      "os_type": "ios",
      "app_version": (info?["CFBundleShortVersionString"] as? String) ?? "",
      "build": (info?["CFBundleVersion"] as? String) ?? "",
    ])
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

  // MARK: - Sentry

  /// Sentry 크래시/에러 리포팅 + 성능 트레이싱 + 프로파일링 + 세션 리플레이 초기화.
  /// 가장 먼저 호출해 초기 크래시까지 포착한다.
  /// DSN·환경은 xcconfig → Info.plist 로 주입된 값을 읽는다(BASE_URL/MIXPANEL_TOKEN 과 동일 패턴).
  private func configureSentry() {
    let info = Bundle.main.infoDictionary
    // SENTRY_DSN 은 xcconfig 에서 스킴(https://)을 제외하고 저장 → 코드에서 붙인다.
    let dsnHost = (info?["SENTRY_DSN"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
    guard !dsnHost.isEmpty else {
      #logError("[Sentry] SENTRY_DSN 미설정 — 초기화 스킵")
      return
    }
    let environment = (info?["SENTRY_ENVIRONMENT"] as? String)?
      .trimmingCharacters(in: .whitespaces) ?? "production"

    SentrySDK.start { options in
      options.dsn = "https://\(dsnHost)"
      options.environment = environment

      #if DEBUG
        options.debug = true
      #else
        options.debug = false
      #endif

      options.releaseName = (info?["CFBundleShortVersionString"] as? String).map {
        "picke-ios@\($0)+\((info?["CFBundleVersion"] as? String) ?? "")"
      }

      // 구조화 로그.
      options.experimental.enableLogs = true

      // 성능 트레이싱 + 프로파일링(트레이싱에 종속).
      options.tracesSampleRate = 1.0
      options.profilesSampleRate = 1.0

      // 크래시 컨텍스트 첨부.
      options.attachScreenshot = true
      options.attachViewHierarchy = true

      // 세션 리플레이 — 텍스트/이미지는 SDK 기본 마스킹(개인정보 보호).
      options.sessionReplay.sessionSampleRate = 0.1
      options.sessionReplay.onErrorSampleRate = 1.0
    }
  }

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
