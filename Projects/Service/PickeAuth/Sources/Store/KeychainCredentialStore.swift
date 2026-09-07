//
//  KeychainCredentialStore.swift
//  PickeAuth
//

import Foundation

import PickeNetworkInterface
import PickeStorageInterface

/// 범용 Keychain 저장소를 PickeNetwork 의 credential 저장 계약으로 변환한다.
final class KeychainCredentialStore: CredentialStore {
  /// access token 과 refresh token 을 보관하는 보안 저장소다.
  private let keychain: any KeychainManaging

  init(keychain: any KeychainManaging) {
    self.keychain = keychain
  }

  /// 저장된 토큰 쌍이 모두 유효할 때만 credential 을 복원한다.
  func load() -> PickeCredential? {
    guard let accessToken = keychain.accessToken(),
          !accessToken.isEmpty,
          let refreshToken = keychain.refreshToken(),
          !refreshToken.isEmpty
    else {
      return nil
    }
    return PickeCredential(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: JWTDecoder.decodeExpiration(accessToken)
    )
  }

  /// access token 과 refresh token 을 각각의 보안 키로 저장한다.
  func save(_ credential: PickeCredential) {
    keychain.save(
      accessToken: credential.accessToken,
      refreshToken: credential.refreshToken
    )
  }

  /// 인증 종료 시 보안 저장소의 모든 인증 값을 제거한다.
  func clear() {
    keychain.clear()
  }
}
