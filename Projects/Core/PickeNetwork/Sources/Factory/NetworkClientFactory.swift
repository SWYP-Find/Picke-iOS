//
//  NetworkClientFactory.swift
//  PickeNetwork
//

import Foundation

import Alamofire
import PickeNetworkInterface

/// `PickeNetworkClient` 조립 진입점. 호출부는 이 팩토리만 알면 된다.
/// baseURL 은 엔드포인트의 `domain` 이 들고 있으므로 팩토리는 인증 조립만 책임진다.
public enum NetworkClientFactory {
  /// 인증 없는 기본 클라이언트. (로그인 / 토큰 재발급처럼 토큰이 아직 없는 요청)
  public static func plain(eventMonitors: [any EventMonitor] = []) -> any PickeNetworkClient {
    NetworkClient(session: SessionFactory.plain(eventMonitors: eventMonitors))
  }

  /// 단일 클라이언트 — 요청의 `authorization` 정책에 따라 요청 시점에 인증 부착을 판단한다.
  /// (`.automatic`: 로그인 상태면 토큰 부착, `.none`: 인증 파이프라인 우회)
  ///
  /// 반환된 `credentials` 로 로그인 / 로그아웃 시점의 토큰 교체를 세션에 반영해야 한다.
  public static func unified(
    store: any CredentialStore,
    refresher: any TokenRefreshing,
    eventMonitors: [any EventMonitor] = []
  ) -> (client: any PickeNetworkClient, credentials: any CredentialUpdating) {
    let (authorizing, credentials) = SessionFactory.authorization(
      store: store,
      refresher: refresher
    )
    return (
      NetworkClient(
        session: SessionFactory.plain(eventMonitors: eventMonitors),
        authorizing: authorizing
      ),
      credentials
    )
  }
}
