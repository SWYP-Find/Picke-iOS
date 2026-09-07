//
//  MockAuthRepository.swift
//  DomainInterface
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

import AuthDomainInterface

public final class MockAuthRepository: AuthInterface, @unchecked Sendable {
  // MARK: - Configuration

  public enum Configuration {
    case success
    case newUser
    case invalidToken
    case networkError
    case refreshSuccess
    case tokenExpired
    case logoutSuccess
    case serverError
    case withdrawSuccess
    case unauthorized
  }

  // MARK: - State

  private var configuration: Configuration = .success
  public private(set) var loginCallCount = 0
  public private(set) var refreshCallCount = 0
  public private(set) var logoutCallCount = 0
  public private(set) var withdrawCallCount = 0
  public private(set) var updateCredentialCallCount = 0
  public private(set) var lastUpdatedTokens: AuthTokens?

  // MARK: - Init

  public init(configuration: Configuration = .success) {
    self.configuration = configuration
  }

  // MARK: - AuthInterface

  public func login(
    provider: SocialType,
    authorizationCode _: String,
    redirectUri _: String?,
    idToken _: String?
  ) async throws -> LoginEntity {
    loginCallCount += 1
    try await Task.sleep(for: .milliseconds(10))

    switch configuration {
    case .success:
      return LoginEntity(
        name: "Mock User",
        isNewUser: false,
        provider: provider,
        token: AuthTokens(
          accessToken: "mock-access-token",
          refreshToken: "mock-refresh-token"
        ),
        userTag: "mock_tag",
        status: "active"
      )

    case .newUser:
      return LoginEntity(
        name: "New User",
        isNewUser: true,
        provider: provider,
        token: AuthTokens(
          accessToken: "mock-access-token",
          refreshToken: "mock-refresh-token"
        ),
        userTag: "new_tag",
        status: "pending"
      )

    case .invalidToken:
      throw MockAuthError.invalidToken

    case .networkError:
      throw MockAuthError.networkError

    default:
      throw MockAuthError.unknownError
    }
  }

  public func refresh() async throws -> AuthTokens {
    refreshCallCount += 1
    try await Task.sleep(for: .milliseconds(10))

    switch configuration {
    case .success, .refreshSuccess:
      return AuthTokens(
        accessToken: "new-access-token",
        refreshToken: "new-refresh-token"
      )
    case .tokenExpired:
      throw MockAuthError.tokenExpired
    default:
      throw MockAuthError.unknownError
    }
  }

  public func logout() async throws -> AuthExitEntity {
    logoutCallCount += 1
    try await Task.sleep(for: .milliseconds(10))

    switch configuration {
    case .success, .logoutSuccess:
      return AuthExitEntity(loggedOut: true)
    case .serverError:
      throw MockAuthError.serverError
    default:
      throw MockAuthError.unknownError
    }
  }

  public func withDraw(reason _: String) async throws -> WithdrawEntity {
    withdrawCallCount += 1
    try await Task.sleep(for: .milliseconds(10))

    switch configuration {
    case .success, .withdrawSuccess:
      return WithdrawEntity(isSuccess: true)
    case .unauthorized:
      throw MockAuthError.unauthorized
    default:
      throw MockAuthError.unknownError
    }
  }

  public func updateSessionCredential(with tokens: AuthTokens) async {
    updateCredentialCallCount += 1
    lastUpdatedTokens = tokens
  }
}

// MARK: - Mock Errors

public enum MockAuthError: Error, LocalizedError {
  case invalidToken
  case networkError
  case tokenExpired
  case serverError
  case unauthorized
  case unknownError

  public var errorDescription: String? {
    switch self {
    case .invalidToken: "Invalid authentication token"
    case .networkError: "Network connection error"
    case .tokenExpired: "Authentication token has expired"
    case .serverError: "Internal server error"
    case .unauthorized: "Unauthorized access"
    case .unknownError: "Unknown authentication error"
    }
  }
}
