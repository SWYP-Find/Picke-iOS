//
//  SessionFactory.swift
//  PickeNetwork
//

import Foundation

import Alamofire
import PickeNetworkInterface

enum SessionFactory {
  static func plain(eventMonitors: [any EventMonitor] = []) -> Session {
    Session(
      configuration: configuration,
      eventMonitors: [PickeEventMonitor()] + eventMonitors
    )
  }

  /// 요청별 인증 조립용 공유 인터셉터 묶음.
  /// `AuthenticationInterceptor` 인스턴스가 하나여야 refresh single-flight 가 보장된다 —
  /// authorizing(요청 조립)과 credentials(로그인 / 로그아웃 교체)가 같은 인스턴스를 본다.
  static func authorization(
    store: any CredentialStore,
    refresher: any TokenRefreshing
  ) -> (authorizing: AuthorizingInterceptor, credentials: any CredentialUpdating) {
    let interceptor = AuthenticationInterceptor(
      authenticator: PickeAuthenticator(refresher: refresher, store: store),
      credential: store.load()
    )
    return (
      AuthorizingInterceptor(base: interceptor),
      CredentialUpdater(interceptor: interceptor)
    )
  }

  /// 성능 최적화된 URLSession 설정(커넥션 풀 / 캐시 / keep-alive) + 공통 정적 헤더.
  private static var configuration: URLSessionConfiguration {
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

    var headers = DefaultHeaders.headers.dictionary
    headers["Connection"] = "keep-alive"
    headers["Keep-Alive"] = "timeout=120, max=1000"
    configuration.httpAdditionalHeaders = headers

    return configuration
  }
}
