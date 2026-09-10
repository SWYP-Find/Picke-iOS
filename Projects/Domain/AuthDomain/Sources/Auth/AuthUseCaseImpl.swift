//
//  AuthUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

import AuthDomainInterface

import ComposableArchitecture
import PickeStorageInterface
import PickeAuthInterface

public struct AuthUseCaseImpl: AuthUseCaseInterface {
  @Dependency(\.authRepository) var authRepository
  @Dependency(\.authService) private var authService: any AuthService
  @Dependency(\.sessionCacheInvalidator) private var sessionCacheInvalidator
  @Shared(.userSession) var userSession: UserSession

  public init() {}

  // MARK: - 로그인

  public func login(
    provider: SocialType,
    authorizationCode: String,
    redirectUri: String?,
    idToken: String?
  ) async throws -> LoginEntity {
    let result = try await authRepository.login(
      provider: provider,
      authorizationCode: authorizationCode,
      redirectUri: redirectUri,
      idToken: idToken
    )

    $userSession.withLock {
      $0.accessToken = result.token.accessToken
      $0.oauthRefreshToken = result.token.oauthRefreshToken
      $0.provider = result.provider
      $0.name = result.name
    }
    await authRepository.updateSessionCredential(with: result.token)

    return result
  }

  public func refresh() async throws -> AuthTokens {
    let tokens = try await authRepository.refresh()
    await authRepository.updateSessionCredential(with: tokens)
    return tokens
  }

  public func logout() async throws -> AuthExitEntity {
    let result = try await authRepository.logout()
    await authService.signOut()
    await sessionCacheInvalidator.invalidate()
    return result
  }

  public func withDraw(reason: String) async throws -> WithdrawEntity {
    let result = try await authRepository.withDraw(reason: reason)
    if result.withdrawn {
      await authService.signOut()
      await sessionCacheInvalidator.invalidate()
    }
    return result
  }

  public func updateSessionCredential(with tokens: AuthTokens) async {
    await authRepository.updateSessionCredential(with: tokens)
  }
}
