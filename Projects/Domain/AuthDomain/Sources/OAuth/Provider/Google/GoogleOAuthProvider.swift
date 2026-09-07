//
//  GoogleOAuthProvider.swift
//  UseCase
//
//  Created by Wonji Suh  on 12/29/25.
//

import Dependencies
@preconcurrency import AuthDomainInterface
import Foundation
import Sharing

public final class GoogleOAuthProvider: GoogleOAuthProviderInterface, @unchecked Sendable {
  @Dependency(\.googleOAuthRepository) private var googleRepository: GoogleOAuthInterface
  @Shared(.userSession) var userSession: UserSession
  public init() {}

  public func signInWithToken(token _: String) async throws -> GoogleOAuthPayload {
    Log.info("Starting Google OAuth flow")
    let payload = try await googleRepository.signIn()
    $userSession.withLock { $0.accessToken = payload.accessToken ?? "" }
    Log.debug("google authCode", payload.authorizationCode)
    return payload
  }
}
