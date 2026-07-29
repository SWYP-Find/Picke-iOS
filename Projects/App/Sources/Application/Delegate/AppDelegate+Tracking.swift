//
//  AppDelegate+Tracking.swift
//  Picke
//

import AppTrackingTransparency
import LogMacro
import UIKit

extension AppDelegate {
  /// ATT(광고 식별자) 권한 요청. AdFit·AdMob 모두 IDFA 가 있어야 맞춤 광고를 집행한다.
  ///
  /// didFinishLaunching 시점엔 앱이 아직 active 가 아니라 팝업이 뜨지 않고 `.notDetermined`
  /// 로 즉시 반환된다(그러면 다시 물어볼 기회가 사라진다). 그래서 최초 active 알림을 한 번
  /// 받은 뒤 요청한다.
  func requestTrackingAuthorizationWhenActive() {
    guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

    trackingAuthorizationObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        if let observer = self.trackingAuthorizationObserver {
          NotificationCenter.default.removeObserver(observer)
          self.trackingAuthorizationObserver = nil
        }
        let status = await ATTrackingManager.requestTrackingAuthorization()
        #logDebug("[ATT] 추적 권한 상태: \(status.rawValue)")
      }
    }
  }
}
