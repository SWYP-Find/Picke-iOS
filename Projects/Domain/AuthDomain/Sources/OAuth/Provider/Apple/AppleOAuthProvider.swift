//
//  AppleOAuthProvider.swift
//  UseCase
//
//  Created by Wonji Suh  on 12/29/25.
//

import Foundation
import PickeCoreLogger
import Dependencies
import AuthenticationServices
@preconcurrency import AuthDomainInterface
import Sharing

public final class AppleOAuthProvider: AppleOAuthProviderInterface, @unchecked Sendable {
  @Dependency(\.appleOAuthRepository) private var appleRepository: AppleOAuthInterface
  @Shared(.userSession) var userSession: UserSession
  public init() {}

  public func signInWithCredential(
    credential: ASAuthorizationAppleIDCredential,
    nonce: String
  ) async throws -> AppleOAuthPayload {
    let payload = try await appleRepository.signInWithCredential(credential, nonce: nonce)
    PickeLogger.info("Apple sign-in completed through repository with credential", category: .auth)
    return payload
  }

  public func signIn() async throws -> AppleOAuthPayload {
    let payload = try await appleRepository.signIn()
    PickeLogger.info("Apple sign-in completed through repository (direct)", category: .auth)
    return payload
  }

  private func formatDisplayName(_ components: PersonNameComponents?) -> String? {
    guard let components else { return nil }
    let formatter = PersonNameComponentsFormatter()
    let name = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty ? nil : name
  }
}

