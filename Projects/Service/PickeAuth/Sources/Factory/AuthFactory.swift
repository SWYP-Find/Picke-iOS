//
//  AuthFactory.swift
//  PickeAuth
//

import Foundation
import os

import PickeAuthInterface
import PickeNetwork
import PickeNetworkInterface
import PickeStorageInterface

/// Keychain, refresh 클라이언트, 인증 클라이언트를 하나의 인증 서비스로 조립한다.
public enum AuthFactory {
  /// refresh 전용(비인증) 클라이언트와 Keychain 으로 완성된 인증 서비스를 생성한다.
  public static func make(
    refreshClient: any PickeNetworkClient = NetworkClientFactory.plain(),
    keychain: any KeychainManaging
  ) -> any AuthService & AuthenticatedClientProvider {
    let store = GuardedCredentialStore(base: KeychainCredentialStore(keychain: keychain))
    let relay = AuthFailureRelay()
    let authenticated = NetworkClientFactory.unified(
      store: store,
      refresher: TokenRefresher(client: refreshClient) {
        await relay.fire()
      }
    )
    let auth = PickeAuth(
      authenticatedClient: authenticated.client,
      store: store,
      credentials: authenticated.credentials
    )
    relay.set { [weak auth] in
      await auth?.handleAuthFailure()
    }
    return auth
  }
}

private final class AuthFailureRelay: Sendable {
  /// 동기 Factory 조립 중 나중에 생성되는 PickeAuth 실패 핸들러를 연결한다.
  private let handler = OSAllocatedUnfairLock<(@Sendable () async -> Void)?>(initialState: nil)

  /// PickeAuth 생성 이후 refresh 실패 핸들러를 원자적으로 등록한다.
  func set(_ handler: @escaping @Sendable () async -> Void) {
    self.handler.withLock {
      $0 = handler
    }
  }

  /// 등록된 실패 핸들러를 lock 밖에서 비동기로 실행한다.
  func fire() async {
    let handler = handler.withLock { $0 }
    await handler?()
  }
}
