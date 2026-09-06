//
//  RewardedAdClient.swift
//  Ad
//

import Foundation

import ComposableArchitecture

/// 리워드 광고 표시 계약.
///
/// 이 타입은 GoogleMobileAds 를 알지 못한다. 실제로 광고를 로드/표시하는 구현은
/// `Ad`(Sources) 의 `liveValue` 에만 있고, 화면들은 이 인터페이스만 의존한다.
public struct RewardedAdClient: Sendable {
  /// 리워드 광고를 로드/표시하고 보상 획득 여부를 반환.
  public var showRewardedAd: @Sendable () async -> Bool

  public init(showRewardedAd: @escaping @Sendable () async -> Bool) {
    self.showRewardedAd = showRewardedAd
  }
}

/// 테스트/프리뷰 기본값은 인터페이스가 갖는다. `liveValue` 는 구현 모듈이 `DependencyKey` 로 채운다
/// — 그래야 테스트 타깃이 GoogleMobileAds SDK 를 링크하지 않는다.
extension RewardedAdClient: TestDependencyKey {
  public static let testValue = RewardedAdClient(showRewardedAd: { false })
  public static let previewValue = testValue
}

public extension DependencyValues {
  var rewardedAdClient: RewardedAdClient {
    get { self[RewardedAdClient.self] }
    set { self[RewardedAdClient.self] = newValue }
  }
}
