import UIKit
import WeaveDI
import Firebase
import GoogleMobileAds
import LogMacro
import Mixpanel
import MixpanelSessionReplay


class AppDelegate: UIResponder, UIApplicationDelegate {
  let mixPanelKey = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_TOKEN") as? String
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    #logDebug(
      "Mixpanel initialize",
      [
        "token_exists": !(mixPanelKey?.isEmpty ?? true),
        "token_prefix": String((mixPanelKey ?? "").prefix(6))
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
    }

    return true
  }
  
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
  
  func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
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
