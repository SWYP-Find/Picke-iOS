//
//  RewardedAdClient+Live.swift
//  AdService
//

import Foundation
import UIKit

import AdServiceInterface
import AnalyticsServiceInterface
import ComposableArchitecture
import GoogleMobileAds
import LogMacro

// MARK: - Live

extension RewardedAdClient: DependencyKey {
  public static let liveValue = RewardedAdClient(
    showRewardedAd: {
      @Dependency(\.analyticsUseCase) var analyticsUseCase
      // 클로저에 UseCase 통째로 붙잡지 않도록 track 만 떼어 넘긴다(Sendable).
      let track = analyticsUseCase.track
      return await RewardedAdPresenter(
        onClick: { track(.adClick(AdClickData(placement: .charge, format: .rewarded))) }
      ).present()
    }
  )
}

/// 리워드 광고 1회 표시를 책임지는 프레젠터. 표시 종료(보상/닫힘/실패)까지 self 를 유지한다.
@MainActor
private final class RewardedAdPresenter: NSObject, FullScreenContentDelegate {
  // 리워드 광고 유닛 ID — xcconfig(REWARD_AD_UNIT) → Info.plist → Bundle 에서 주입.
  // 값이 없으면 Google 테스트 ID 로 폴백.
  private let adUnitID: String = {
    let key = Bundle.main.object(forInfoDictionaryKey: "REWARD_AD_UNIT") as? String
    if let key, !key.isEmpty { return key }
    return "ca-app-pub-3940256099942544/1712485313"
  }()

  private var rewardedAd: RewardedAd?
  private var continuation: CheckedContinuation<Bool, Never>?
  private var earnedReward = false
  private var retainSelf: RewardedAdPresenter?

  /// 광고 클릭 시 호출. 트래킹은 호출부(liveValue)가 주입해 프레젠터는 분석 모듈을 모른다.
  private let onClick: @Sendable () -> Void

  init(onClick: @escaping @Sendable () -> Void) {
    self.onClick = onClick
    super.init()
  }

  func present() async -> Bool {
    do {
      let ad = try await RewardedAd.load(with: adUnitID, request: Request())
      rewardedAd = ad
      ad.fullScreenContentDelegate = self

      guard let rootViewController = Self.topViewController() else {
        Log.error("[RewardedAd] rootViewController 를 찾지 못했습니다")
        return false
      }

      return await withCheckedContinuation { continuation in
        self.continuation = continuation
        self.retainSelf = self
        ad.present(from: rootViewController) { [weak self] in
          self?.earnedReward = true
          Log.debug("[RewardedAd] 보상 획득")
        }
      }
    } catch {
      Log.error("[RewardedAd] 광고 로드 실패: \(error.localizedDescription)")
      return false
    }
  }

  // MARK: FullScreenContentDelegate

  func adDidDismissFullScreenContent(_: FullScreenPresentingAd) {
    finish(earnedReward)
  }

  func adDidRecordClick(_: FullScreenPresentingAd) {
    Log.debug("[RewardedAd] 광고 클릭")
    onClick()
  }

  func ad(_: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
    Log.error("[RewardedAd] 광고 표시 실패: \(error.localizedDescription)")
    finish(false)
  }

  private func finish(_ result: Bool) {
    continuation?.resume(returning: result)
    continuation = nil
    rewardedAd = nil
    retainSelf = nil
  }

  /// 현재 화면 최상단(모달 포함) ViewController — 광고/클릭 랜딩 표시 기준.
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
