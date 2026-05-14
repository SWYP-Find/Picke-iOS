//
//  KakaoOAuthProviderInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 5/14/26.
//

import Entity
import Foundation
import WeaveDI

/// Kakao OAuth Provider Interface 프로토콜
public protocol KakaoOAuthProviderInterface: Sendable {
  func signInWithToken(token: String) async throws -> KakaoOAuthPayload
}

/// Kakao OAuth Provider의 DependencyKey 구조체
public struct KakaoOAuthProviderDependency: DependencyKey {
  public static var liveValue: KakaoOAuthProviderInterface {
    UnifiedDI.resolve(KakaoOAuthProviderInterface.self) ?? MockKakaoOAuthProvider()
  }

  public static var testValue: KakaoOAuthProviderInterface {
    UnifiedDI.resolve(KakaoOAuthProviderInterface.self) ?? MockKakaoOAuthProvider()
  }

  public static var previewValue: KakaoOAuthProviderInterface = testValue
}

/// DependencyValues extension으로 간편한 접근 제공
public extension DependencyValues {
  var kakaoOAuthProvider: KakaoOAuthProviderInterface {
    get { self[KakaoOAuthProviderDependency.self] }
    set { self[KakaoOAuthProviderDependency.self] = newValue }
  }
}

/// 테스트용 Mock 구현체
public struct MockKakaoOAuthProvider: KakaoOAuthProviderInterface {
  public init() {}

  public func signInWithToken(token _: String) async throws -> KakaoOAuthPayload {
    KakaoOAuthPayload(
      idToken: "mock_kakao_id_token",
      accessToken: "mock_kakao_access_token",
      refreshToken: "mock_kakao_refresh_token",
      authorizationCode: "mock_kakao_auth_code",
      displayName: "Mock Kakao User",
      codeVerifier: "mock_kakao_code_verifier",
      redirectUri: "mock://kakao/callback"
    )
  }
}
