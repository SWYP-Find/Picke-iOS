//
//  RewardedAdClient.swift
//  Ad
//

import Foundation

import ComposableArchitecture

/// 리워드 광고 표시 계약.
public struct RewardedAdClient: Sendable {
  /// 리워드 광고를 로드/표시하고 보상 획득 여부를 반환.
  public var showRewardedAd: @Sendable () async -> Bool

  public init(showRewardedAd: @escaping @Sendable () async -> Bool) {
    self.showRewardedAd = showRewardedAd
  }
}

/// 테스트/프리뷰 기본값은 인터페이스가 갖는다. `liveValue` 는 구현 모듈이 `DependencyKey` 로 채운다
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
