//
//  OptimizedSessionManager.swift
//  AuthDomain
//
//  Created by Wonji Suh on 5/14/26.
//

import Alamofire
import AuthDomainInterface
import Foundation
import PickeNetwork
import PickeStorageInterface
import WeaveDI

/// 네트워킹 성능 최적화된 세션 매니저
public final class OptimizedSessionManager {
  public static let shared = OptimizedSessionManager()

  @Dependency(\.keychainManager) var keychainManager

  var credential: AccessTokenCredential?
  /// 인증 세션(인터셉터·이벤트 모니터 부착). 대부분의 요청에 사용.
  let session: Session
  /// 비인증 세션(로그인/토큰 재발급 등 토큰이 아직 없는 요청). 인터셉터 없음.
  let plainSession: Session

  private init() {
    // 세션 조립은 SessionFactory 가 담당(config·인터셉터·이벤트 모니터). 동작 보존.
    session = SessionFactory.authenticated(
      interceptor: AuthInterceptor(),
      eventMonitors: [SessionInvalidationMonitor()]
    )
    plainSession = SessionFactory.plain(
      eventMonitors: [SessionInvalidationMonitor()]
    )

    setupInitialCredential()
  }

  public func configureNetworkSessions() {
    NetworkSessionRegistry.shared.configure(
      authorizedSession: session,
      plainSession: plainSession
    )
  }

  public func updateCredential(with tokens: AuthTokens) {
    credential = AccessTokenCredential.make(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken
    )
  }

  public func clear() {
    credential = nil
    session.session.configuration.urlCache?.removeAllCachedResponses()
  }
}

private extension OptimizedSessionManager {
  func setupInitialCredential() {
    if let loaded = loadCredentialFromKeychain() {
      credential = loaded
    }
  }

  func loadCredentialFromKeychain() -> AccessTokenCredential? {
    let access = keychainManager.accessToken()
    let refresh = keychainManager.refreshToken()
    guard let access, let refresh, !access.isEmpty, !refresh.isEmpty else { return nil }
    return AccessTokenCredential.make(accessToken: access, refreshToken: refresh)
  }
}
