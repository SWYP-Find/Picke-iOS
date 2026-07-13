//
//  SessionFactory.swift
//  Repository
//
//  Alamofire `Session` 조립 전담(Joongna JNNetwork SessionFactory 구조 참고).
//  config(커넥션 풀·캐시·타임아웃) / 인증 인터셉터 / 이벤트 모니터(로깅·세션 무효화) 를 한 곳에서 묶는다.
//  동작 보존: 기존 OptimizedSessionManager 의 최적화 설정을 그대로 옮겨왔다.
//

import Alamofire
import Foundation

/// 인증(authenticated) / 비인증(plain) 세션 조립 팩토리.
enum SessionFactory {
  /// 인증 세션. `AuthInterceptor`(401 자동 refresh·retry)를 얹는다. 대부분의 요청에 사용.
  static func authenticated() -> Session {
    Session(
      configuration: configuration(),
      interceptor: AuthInterceptor(),
      eventMonitors: monitors()
    )
  }

  /// 비인증 세션. 로그인/토큰 재발급처럼 아직 토큰이 없는 요청에 사용(인터셉터 없음).
  static func plain() -> Session {
    Session(
      configuration: configuration(),
      eventMonitors: monitors()
    )
  }
}

private extension SessionFactory {
  /// 성능 최적화된 URLSession 설정(커넥션 풀 / 캐시 / keep-alive).
  static func configuration() -> URLSessionConfiguration {
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

    return configuration
  }

  /// 두 세션 공통 이벤트 모니터. 요청/응답 로깅 + USER_404/AUTH_401 세션 무효화.
  static func monitors() -> [any EventMonitor] {
    [PickeEventMonitor(), SessionInvalidationMonitor()]
  }
}
