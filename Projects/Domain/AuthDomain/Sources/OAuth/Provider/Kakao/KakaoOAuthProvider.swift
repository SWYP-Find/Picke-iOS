//
//  KakaoOAuthProvider.swift
//  UseCase
//
//  Created by Wonji Suh  on 5/14/26.
//

import Dependencies
@preconcurrency import AuthDomainInterface
import Foundation
import LogMacro
import Sharing

public final class KakaoOAuthProvider: KakaoOAuthProviderInterface, @unchecked Sendable {
  @Dependency(\.kakaoOAuthRepository) private var kakaoRepository: KakaoOAuthInterface
  @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
  public init() {}

  public func signInWithToken(token _: String) async throws -> KakaoOAuthPayload {
    Log.info("Starting Kakao OAuth flow")
    let payload = try await kakaoRepository.signIn()
    $userSession.withLock { $0.accessToken = payload.accessToken }
    return payload
  }
}
