//
//  OptimizedSessionManager.swift
//  Repository
//
//  Created by Wonji Suh on 5/14/26.
//

import Alamofire
import AuthDomainInterface
import DomainInterface
import Entity
import Foundation
import WeaveDI

/// 네트워킹 성능 최적화된 세션 매니저
public final class OptimizedSessionManager {
  public static let shared = OptimizedSessionManager()

  @Dependency(\.keychainManager) var keychainManager

  var credential: AccessTokenCredential?
  let session: Session

  private init() {
    let configuration = URLSessionConfiguration.default

    configuration.httpMaximumConnectionsPerHost = 6
    configuration.requestCachePolicy = .useProtocolCachePolicy

    configuration.timeoutIntervalForRequest = 30.0
    configuration.timeoutIntervalForResource = 120.0

    configuration.urlCache = URLCache(
      memoryCapacity: 50 * 1024 * 1024,
      diskCapacity: 200 * 1024 * 1024,
      diskPath: "picke_network_cache"
    )

    configuration.multipathServiceType = .handover
    configuration.allowsCellularAccess = true
    configuration.allowsExpensiveNetworkAccess = true
    configuration.allowsConstrainedNetworkAccess = false

    configuration.httpAdditionalHeaders = [
      "Connection": "keep-alive",
      "Keep-Alive": "timeout=120, max=1000",
    ]

    session = Session(
      configuration: configuration,
      interceptor: AuthInterceptor()
    )

    setupInitialCredential()
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
