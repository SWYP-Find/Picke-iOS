//
//  MixpanelConfiguration.swift
//  PickeAnalytics
//

import Foundation

import LogMacro
import Mixpanel
import MixpanelSessionReplay
import PickeNetwork

/// Mixpanel 기동과 공통 프로퍼티·세션 리플레이·네트워크 텔레메트리 연결.
enum MixpanelConfiguration {
  private static var token: String? {
    Bundle.main.object(forInfoDictionaryKey: "MIXPANEL_TOKEN") as? String
  }

  static func configure() {
    let token = token
    #logDebug(
      "Mixpanel initialize",
      [
        "token_exists": !(token?.isEmpty ?? true),
        "token_prefix": String((token ?? "").prefix(6)),
      ]
    )
    Mixpanel.initialize(token: token ?? "", trackAutomaticEvents: true)

    // 모든 이벤트에 자동 첨부되는 공통 슈퍼 프로퍼티(플랫폼/버전). is_logged_in 은 로그인/로그아웃이 관리.
    let info = Bundle.main.infoDictionary
    Mixpanel.mainInstance().registerSuperProperties([
      "os_type": "ios",
      "app_version": (info?["CFBundleShortVersionString"] as? String) ?? "",
      "build": (info?["CFBundleVersion"] as? String) ?? "",
    ])

    configureSessionReplay(token: token)
    configureNetworkTelemetry()
  }

  /// NOTE: MixpanelSessionReplay 1.4.0의 _UIReparentingView swizzling이
  /// SwiftUI UIHostingController.view에 적용되며 콘솔 경고가 출력될 수 있음 (기능 영향 없음).
  /// SDK 측 SwiftUI 호환성 개선 시 경고 자동 해소 예정.
  private static func configureSessionReplay(token: String?) {
    guard !(token?.isEmpty ?? true) else { return }

    var config = MPSessionReplayConfig(wifiOnly: false)
    config.enableSessionReplayOniOS26AndLater = true

    MPSessionReplay.initialize(
      token: Mixpanel.mainInstance().apiToken,
      distinctId: Mixpanel.mainInstance().distinctId,
      config: config
    )
  }

  private static func configureNetworkTelemetry() {
    NetworkTelemetry.shared.configure { event in
      var properties: Properties = [
        "source": event.source,
        "method": event.method,
        "host": event.host,
        "path": event.path,
        "duration_ms": event.durationMilliseconds,
        "success": event.isSuccess,
      ]
      if let statusCode = event.statusCode {
        properties["status_code"] = statusCode
      }
      Mixpanel.mainInstance().track(
        event: "network_request",
        properties: properties
      )
    }
  }
}
