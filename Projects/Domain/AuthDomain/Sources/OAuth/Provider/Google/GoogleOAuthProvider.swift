//
//  GoogleOAuthProvider.swift
//  UseCase
//
//  Created by Wonji Suh  on 12/29/25.
//

import Dependencies
import PickeCoreLogger
@preconcurrency import AuthDomainInterface
import Foundation
import Sharing

public final class GoogleOAuthProvider: GoogleOAuthProviderInterface, @unchecked Sendable {
  @Dependency(\.googleOAuthRepository) private var googleRepository: GoogleOAuthInterface
  @Shared(.userSession) var userSession: UserSession
  public init() {}

  public func signInWithToken(token _: String) async throws -> GoogleOAuthPayload {
    PickeLogger.info("Starting Google OAuth flow", category: .auth)
    let payload = try await googleRepository.signIn()
    $userSession.withLock { $0.accessToken = payload.accessToken ?? "" }
    PickeLogger.debug("google authCode: \(payload.authorizationCode)", category: .auth)
    return payload
  }
}
