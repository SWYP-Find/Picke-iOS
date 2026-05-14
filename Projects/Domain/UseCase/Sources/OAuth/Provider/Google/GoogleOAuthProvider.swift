//
//  GoogleOAuthProvider.swift
//  UseCase
//
//  Created by Wonji Suh  on 12/29/25.
//

import Dependencies
import DomainInterface
@preconcurrency import Entity
import Foundation
import LogMacro
import Sharing

public final class GoogleOAuthProvider: GoogleOAuthProviderInterface, @unchecked Sendable {
  @Dependency(\.googleOAuthRepository) private var googleRepository
  @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
  public init() {}

  /// Google OAuth 인증 후 백엔드 `/api/v1/auth/login/google` 에 보낼
  /// 서버용 authorization code (`serverAuthCode`) 를 반환.
  /// idToken 이 필요하면 별도 메서드로 분리할 것.
  public func signInWithToken(
    token _: String
  ) async throws -> String {
    Log.info("Starting Google OAuth flow")
    let payload = try await googleRepository.signIn()
    $userSession.withLock { $0.accessToken = payload.accessToken ?? "" }

    guard let authCode = payload.authorizationCode, !authCode.isEmpty else {
      Log.error("Google serverAuthCode missing — check GIDConfiguration.serverClientID")
      throw AuthError.invalidCredential("Google 서버 인증 코드가 없습니다. serverClientID 설정을 확인하세요.")
    }

    Log.debug("google authCode", authCode)
    return authCode
  }
}
