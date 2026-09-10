//
//  AppDelegate+Configure.swift
//  Picke
//

import AppTrackingTransparency
import GoogleMobileAds
import PickeCoreLogger
import UIKit
import UserNotifications

import DomainAssembly
import PickeConfig
import PickeDesignKit
import ServiceAssembly

extension AppDelegate {
  /// 기동 초기화 진입점. 순서에 의미가 있다.
  /// 외부 SDK 부팅은 Firebase 를 PickeConfig 가, Sentry·Mixpanel 을 PickeAnalytics 가 맡는다.
  func configure() {
    configureFonts()
    FirebaseConfiguration.configure()
    PickeAnalyticsConfiguration.configure()
    configureAdMob()
    requestTrackingAuthorizationWhenActive()
    configurePushNotifications()
    configureImageDownloader()
  }

  // MARK: - 폰트

  func configureFonts() {
    PretendardFontFamily.registerFonts()
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
      PickeLogger.debug("[AdMob] 테스트 디바이스 등록 — 내부 기기 \(internalDeviceIdentifiers.count)대 + 시뮬레이터", category: .app)
    #endif
  }

  // MARK: - 이미지 다운로더

  /// Store 수명 밖에서 도는 인프라라 기동 시 한 번만 설정한다.
  func configureImageDownloader() {
    KingfisherConfigurator.configureAuthorizedDownloader(
      storage: StorageAssembly.secureStorage()
    )
  }

  // MARK: - 푸시 알림

  func configurePushNotifications() {
    let center = UNUserNotificationCenter.current()
    center.delegate = self

    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error {
        PickeLogger.error("[Push] 권한 요청 실패: \(error.localizedDescription)", category: .app)
        return
      }
      guard granted else {
        PickeLogger.debug("[Push] 알림 권한 거부됨", category: .app)
        return
      }
      Task { @MainActor in
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  // MARK: - 광고 식별자(ATT)

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
        PickeLogger.debug("[ATT] 추적 권한 상태: \(status.rawValue)", category: .app)
      }
    }
  }
}
