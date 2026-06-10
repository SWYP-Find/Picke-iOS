//
//  RewardedAdClient.swift
//  UseCase
//
//  무료 충전 — GoogleMobileAds 리워드 동영상 광고(네이티브).
//  광고 클릭 시 랜딩(웹뷰)은 SDK 인앱 브라우저로 자동 처리되며,
//  rootViewController 만 올바르게 넘겨주면 된다.
//

import Foundation

import ComposableArchitecture
import LogMacro

import GoogleMobileAds
import UIKit

public struct RewardedAdClient: Sendable {
  /// 리워드 광고를 로드/표시하고 보상 획득 여부를 반환.
  public var showRewardedAd: @Sendable () async -> Bool

  public init(showRewardedAd: @escaping @Sendable () async -> Bool) {
    self.showRewardedAd = showRewardedAd
  }
}

extension RewardedAdClient: DependencyKey {
  public static let liveValue = RewardedAdClient(
    showRewardedAd: { await RewardedAdPresenter().present() }
  )

  public static let testValue = RewardedAdClient(showRewardedAd: { false })
  public static let previewValue = testValue
}

public extension DependencyValues {
  var rewardedAdClient: RewardedAdClient {
    get { self[RewardedAdClient.self] }
    set { self[RewardedAdClient.self] = newValue }
  }
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
