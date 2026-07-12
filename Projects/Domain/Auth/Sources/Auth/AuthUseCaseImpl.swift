//
//  AuthUseCaseImpl.swift
//  UseCase
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

import AuthDomainInterface
import DomainInterface
import Entity

import ComposableArchitecture
import WeaveDI

public struct AuthUseCaseImpl: AuthInterface {
  @Dependency(\.authRepository) var authRepository
  @Dependency(\.keychainManager) private var keychainManager: KeychainManaging
  @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty

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
    keychainManager.save(
      accessToken: result.token.accessToken,
      refreshToken: result.token.refreshToken
    )
    authRepository.updateSessionCredential(with: result.token)

    return result
  }

  public func refresh() async throws -> AuthTokens {
    let tokens = try await authRepository.refresh()
    keychainManager.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
    authRepository.updateSessionCredential(with: tokens)
    return tokens
  }

  public func logout() async throws -> AuthExitEntity {
    let result = try await authRepository.logout()
    keychainManager.clear()
    return result
  }

  public func withDraw(token: String) async throws -> WithdrawEntity {
    let result = try await authRepository.withDraw(token: token)
    if result.withdrawn {
      keychainManager.clear()
    }
    return result
  }

  public func updateSessionCredential(with tokens: AuthTokens) {
    authRepository.updateSessionCredential(with: tokens)
  }
}

extension AuthUseCaseImpl: DependencyKey {
  public static var liveValue = AuthUseCaseImpl()
  public static var testValue = AuthUseCaseImpl()
  public static var previewValue = AuthUseCaseImpl()
}

public extension DependencyValues {
  var authUseCase: AuthUseCaseImpl {
    get { self[AuthUseCaseImpl.self] }
    set { self[AuthUseCaseImpl.self] = newValue }
  }
}
