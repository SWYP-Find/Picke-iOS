//
//  AppDelegate+Configure.swift
//  Picke
//

import GoogleMobileAds
import LogMacro
import UIKit

import DomainAssembly
import ServiceAssembly

extension AppDelegate {
  /// 기동 초기화 진입점. 순서에 의미가 있다.
  /// 관측 SDK(Sentry·Firebase·Mixpanel) 설정은 PickeAnalytics 가 전담한다.
  func configure() {
    PickeAnalyticsConfiguration.configure()
    configureAdMob()
    requestTrackingAuthorizationWhenActive()
    configurePushNotifications()
    configureImageDownloader()
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

  // MARK: - 이미지 다운로더

  /// Store 수명 밖에서 도는 인프라라 기동 시 한 번만 설정한다.
  func configureImageDownloader() {
    KingfisherConfigurator.configureAuthorizedDownloader(
      storage: AppDependencyFactory.secureStorage
    )
  }
}
