//
//  AppDelegate+Configure.swift
//  Picke
//

import Firebase
import GoogleMobileAds
import LogMacro
import Mixpanel
import MixpanelSessionReplay
import PickeNetwork
import UIKit

import DomainAssembly

extension AppDelegate {
  /// 기동 초기화 진입점. 순서에 의미가 있다.
  /// Sentry 를 가장 먼저 올려야 이후 초기화 중 발생한 크래시까지 포착된다.
  func configure() {
    configureSentry()
    configureFirebase()
    configureMixpanel()
    configureAdMob()
    requestTrackingAuthorizationWhenActive()
    configurePushNotifications()
    configureDependencies()
  }

  // MARK: - Firebase

  func configureFirebase() {
    FirebaseApp.configure()
  }

  // MARK: - Mixpanel

  func configureMixpanel() {
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

    initializeMixpanelSessionReplay()
    configureNetworkTelemetry()
  }

  private func configureNetworkTelemetry() {
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

  /// NOTE: MixpanelSessionReplay 1.4.0의 _UIReparentingView swizzling이
  /// SwiftUI UIHostingController.view에 적용되며 콘솔 경고가 출력될 수 있음 (기능 영향 없음).
  /// SDK 측 SwiftUI 호환성 개선 시 경고 자동 해소 예정.
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

  // MARK: - AdMob

  func configureAdMob() {
    registerAdTestDevices()
    MobileAds.shared.start()
  }

  /// 개발/QA 빌드의 AdMob 무효 트래픽 방지 — 내부 기기를 테스트 디바이스로 등록한다.
  ///
  /// 광고 단위 ID 는 Stage/Prod/Release 전 환경 동일(프로덕션)이라 ID 분리로는 막을 수 없다.
  /// 대신 AdMob 공식 방식인 테스트 디바이스 등록을 쓰면 프로덕션 ID 그대로도 내부 기기엔
  /// 테스트 광고가 노출되고, 그 노출·클릭은 실적에 집계되지 않는다.
  ///
  /// 시뮬레이터는 SDK 가 자동으로 테스트 기기로 취급한다. 실기기는 앱을 한 번 실행하면 콘솔에
  /// `To get test ads on this device, set: testDeviceIdentifiers = @[ @"<해시>" ]` 가 찍히므로
  /// 그 해시를 아래 배열에 추가하면 된다.
  func registerAdTestDevices() {
    #if DEBUG || STAGE
      // 팀 내부 실기기 해시 — 콘솔 로그를 보고 추가할 것.
      let internalDeviceIdentifiers: [String] = []

      MobileAds.shared.requestConfiguration.testDeviceIdentifiers = internalDeviceIdentifiers
      #logDebug("[AdMob] 테스트 디바이스 등록 — 내부 기기 \(internalDeviceIdentifiers.count)대 + 시뮬레이터")
    #endif
  }

  // MARK: - DI

  func configureDependencies() {
    AppDependencyFactory.configureNetworkInfrastructure()
  }
}
