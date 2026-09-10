//
//  TokenRefreshing.swift
//  PickeNetworkInterface
//

import Foundation

/// 토큰 refresh 추상. refresh API 호출은 앱(Repository)이 구현한다.
public protocol TokenRefreshing: Sendable {
  func refresh(_ current: PickeCredential) async throws(PickeNetworkError) -> PickeCredential
}
