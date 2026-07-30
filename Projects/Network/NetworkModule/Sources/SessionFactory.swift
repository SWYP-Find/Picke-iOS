//
//  SessionFactory.swift
//  NetworkModule
//

import Alamofire
import Foundation

/// 인증(authenticated) / 비인증(plain) 세션 조립 팩토리.
///
/// 인터셉터·부가 이벤트 모니터는 호출자가 주입한다(NetworkModule 은 인증 주체를 모른다).
public enum SessionFactory {
  /// 인증 세션. 호출자가 넘긴 `interceptor`(401 자동 refresh·retry 등)를 얹는다. 대부분의 요청에 사용.
  public static func authenticated(interceptor: RequestInterceptor, eventMonitors: [any EventMonitor] = []) -> Session {
    Session(
      configuration: configuration(),
      interceptor: interceptor,
      eventMonitors: monitors() + eventMonitors
    )
  }

  /// 비인증 세션. 로그인/토큰 재발급처럼 아직 토큰이 없는 요청에 사용(인터셉터 없음).
  public static func plain(eventMonitors: [any EventMonitor] = []) -> Session {
    Session(
      configuration: configuration(),
      eventMonitors: monitors() + eventMonitors
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

  /// 두 세션 공통 기본 이벤트 모니터(요청/응답 로깅). 인증 관련 모니터는 호출자가 `eventMonitors` 로 추가.
  static func monitors() -> [any EventMonitor] {
    [PickeEventMonitor()]
  }
}
