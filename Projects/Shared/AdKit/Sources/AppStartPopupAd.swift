//
//  AppStartPopupAd.swift
//  AdKit
//

import UIKit
import OSLog

import AdFitSDK

/// 앱 시작 전면 팝업 광고 진입점. `AppStartPopupAd.presentIfNeeded()` 한 줄로 호출한다.
public enum AppStartPopupAd {
  /// 메인 화면 진입 후 호출할 때마다 팝업을 시도한다.
  /// 광고 단위가 없거나 로드에 실패하면 아무것도 뜨지 않는다(무해).
  @MainActor
  public static func presentIfNeeded() {
    AppStartPopupAdPresenter.shared.presentIfNeeded()
  }
}

/// 팝업 1개의 로드/표시/닫기 수명을 관리하는 프레젠터. delegate 콜백까지 self 를 유지한다.
@MainActor
final class AppStartPopupAdPresenter: NSObject, SuperboardPopUpDelegate {
  static let shared = AppStartPopupAdPresenter()

  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Picke",
    category: "AdFit.AppTransition"
  )

  private var popUp: SuperboardPopUp?

  override private init() {}

  func presentIfNeeded() {
    guard popUp == nil else {
      Self.logger.debug("AdFit 앱 전환 광고 건너뜀: 이미 요청 중")
      return
    }

    let adUnitId = Bundle.main.object(forInfoDictionaryKey: "ADFIT_APP_TRANSITION") as? String
    guard let adUnitId, !adUnitId.isEmpty else {
      Self.logger.error("AdFit 앱 전환 광고 단위가 Info.plist에 설정되지 않음")
      return
    }
    guard let rootViewController = Self.topViewController() else {
      Self.logger.error("AdFit 앱 전환 광고를 표시할 ViewController를 찾지 못함")
      return
    }

    let popUp = SuperboardPopUp(adUnitId: adUnitId)
    popUp.delegate = self
    self.popUp = popUp
    Self.logger.info("AdFit 앱 전환 광고 요청 시작")
    // present 는 로드 성공 시에만 모달을 띄운다. 실패하면 adViewDidFailToReceiveAd 만 호출된다.
    popUp.present(rootViewController)
  }

  // MARK: SuperboardPopUpDelegate

  func adViewDidReceiveAd() {
    Self.logger.info("AdFit 앱 전환 광고 수신 성공")
  }

  func adViewDidFailToReceiveAd(error: Error) {
    Self.logger.error(
      "AdFit 앱 전환 광고 수신 실패: \(error.localizedDescription, privacy: .public)"
    )
    popUp = nil
  }

  func adViewDidClickAd() {
    Self.logger.info("AdFit 앱 전환 광고 클릭")
  }

  func adViewControllerClickClose() {
    Self.logger.info("AdFit 앱 전환 광고 닫기")
    popUp = nil
  }

  /// 현재 정책에서는 "오늘 그만 보기"도 일반 닫기와 동일하게 처리한다.
  func adViewControllerClickHideForToday() {
    UserDefaults.standard.removeObject(forKey: "adfit.appTransition.hideUntil")
    Self.logger.info("AdFit 앱 전환 광고 오늘 그만 보기: 숨김 기록을 유지하지 않음")
    popUp = nil
  }

  /// 현재 화면 최상단(모달 포함) ViewController — 팝업을 올릴 기준.
  private static func topViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)

    var top = keyWindow?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
