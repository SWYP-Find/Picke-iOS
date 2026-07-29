//
//  AppDelegate.swift
//  Picke
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  let mixPanelKey = Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_TOKEN") as? String

  /// ATT 팝업을 앱 active 이후로 미루기 위한 1회성 옵저버.
  /// 저장 프로퍼티는 확장에 둘 수 없어 여기 남으며, AppDelegate+Tracking 에서 쓰므로 internal 이다.
  var trackingAuthorizationObserver: NSObjectProtocol?

  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configure()
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
}
