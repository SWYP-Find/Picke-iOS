//
//  CredentialStore.swift
//  PickeNetworkInterface
//

import Foundation

/// 토큰 저장소 추상. 앱이 구현(키체인 등)해 주입한다.
public protocol CredentialStore: Sendable {
  /// 저장된 토큰 (없으면 nil)
  func load() -> PickeCredential?
  /// 토큰 저장 (refresh 후 영속화)
  func save(_ credential: PickeCredential)
  /// 토큰 삭제 (로그아웃 등)
  func clear()
}
