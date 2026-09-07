//
//  KakaoOAuthProvider.swift
//  UseCase
//
//  Created by Wonji Suh  on 5/14/26.
//

import Dependencies
import PickeCoreLogger
@preconcurrency import AuthDomainInterface
import Foundation
import Sharing

public final class KakaoOAuthProvider: KakaoOAuthProviderInterface, @unchecked Sendable {
  @Dependency(\.kakaoOAuthRepository) private var kakaoRepository: KakaoOAuthInterface
  @Shared(.userSession) var userSession: UserSession
  public init() {}

  public func signInWithToken(token _: String) async throws -> KakaoOAuthPayload {
    PickeLogger.info("Starting Kakao OAuth flow", category: .auth)
    let payload = try await kakaoRepository.signIn()
    $userSession.withLock { $0.accessToken = payload.accessToken }
    return payload
  }
}
