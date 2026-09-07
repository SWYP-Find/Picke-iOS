//
//  AuthService.swift
//  PickeAuthInterface
//

import Foundation

/// 앱의 인증 상태를 저장소와 네트워크 세션에 동시에 반영하는 단일 진입점.
public protocol AuthService: Sendable {
  /// 저장소에 유효한 access/refresh token 쌍이 있는지 확인한다.
  var isLoggedIn: Bool { get async }
  /// 저장된 refresh token 을 반환한다.
  var refreshToken: String? { get async }

  /// 로그인 성공 토큰을 영속화하고 이후 인증 요청에 즉시 반영한다.
  func signIn(accessToken: String, refreshToken: String) async
  /// 영속 토큰과 현재 네트워크 세션 credential 을 함께 제거한다.
  func signOut() async
}

public extension Notification.Name {
  /// refresh token 이 서버에서 거부되어 재로그인이 필요할 때 발행된다.
  static let pickeAuthSessionDidExpire = Notification.Name("pickeauth.session.didExpire")
}
