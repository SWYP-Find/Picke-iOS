import Firebase
import GoogleMobileAds
import LogMacro
import Mixpanel
import MixpanelSessionReplay
import UIKit
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

    // 🧠 메모리 관리 시스템 초기화 (우선) - 모듈 분리 완료시 활성화
    // Task { @MainActor in
    //   _ = MemoryPressureManager.shared
    //   #if DEBUG
    //   _ = MemoryLeakDetector.shared
    //   print("🚀 [AppDelegate] Memory management systems initialized")
    //   #endif
    // }

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
