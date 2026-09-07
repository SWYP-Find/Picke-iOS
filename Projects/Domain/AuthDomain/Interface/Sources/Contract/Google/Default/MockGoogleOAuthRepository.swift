//
//  MockGoogleOAuthRepository.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 12/29/25.
//

import Foundation

public actor MockGoogleOAuthRepository: GoogleOAuthInterface {
  public init() {}

  // MARK: - Configuration

  public enum Configuration {
    case success
    case failure
    case customUser(String)
    case networkError
    case customDelay(TimeInterval)

    var shouldSucceed: Bool {
      switch self {
      case .success, .customUser, .customDelay:
        true
      case .failure, .networkError:
        false
      }
    }

    var delay: TimeInterval {
      switch self {
      case let .customDelay(delay):
        delay
      default:
        0.1
      }
    }

    var mockUserName: String {
      switch self {
      case let .customUser(name):
        name
      default:
        "Mock Google User"
      }
    }
  }

  // MARK: - State

  private var configuration: Configuration = .success
  private var signInCallCount = 0
  private var lastSignInCall: Date?

  // MARK: - Public Configuration Methods

  public init(configuration: Configuration = .success) {
    self.configuration = configuration
  }

  public func setConfiguration(_ configuration: Configuration) {
    self.configuration = configuration
    signInCallCount = 0
    lastSignInCall = nil
  }

  public func getSignInCallCount() -> Int {
    signInCallCount
  }

  public func getLastSignInCall() -> Date? {
    lastSignInCall
  }

  public func reset() {
    configuration = .success
    signInCallCount = 0
    lastSignInCall = nil
  }

  // MARK: - GoogleOAuthRepositoryProtocol Implementation

  public func signIn() async throws -> GoogleOAuthPayload {
    signInCallCount += 1
    lastSignInCall = Date()

    if configuration.delay > 0 {
      try await Task.sleep(for: .seconds(configuration.delay))
    }

    // Handle failure scenarios
    if !configuration.shouldSucceed {
      switch configuration {
      case .failure:
        throw MockGoogleOAuthError.signInFailed
      case .networkError:
        throw MockGoogleOAuthError.networkError
      default:
        throw MockGoogleOAuthError.unknownError
      }
    }

    // Return success payload
    return GoogleOAuthPayload(
      idToken: createMockIDToken(),
      accessToken: createMockAccessToken(),
      authorizationCode: createMockAuthCode(),
      displayName: configuration.mockUserName,
      redirectUri: "https://picke.store/oauth/google"
    )
  }

  // MARK: - Private Helper Methods

  private func createMockIDToken() -> String {
    "mock.google.idtoken.\(UUID().uuidString.prefix(8))"
  }

  private func createMockAccessToken() -> String {
    "ya29.mock-google-access-token-\(UUID().uuidString.prefix(12))"
  }

  private func createMockAuthCode() -> String {
    "4/mock-google-auth-code-\(UUID().uuidString.prefix(10))"
  }
}

// MARK: - Convenience Static Methods

public extension MockGoogleOAuthRepository {
  /// Creates a pre-configured actor for success scenario
  static func success() -> MockGoogleOAuthRepository {
    MockGoogleOAuthRepository(configuration: .success)
  }

  /// Creates a pre-configured actor for failure scenario
  static func failure() -> MockGoogleOAuthRepository {
    MockGoogleOAuthRepository(configuration: .failure)
  }

  /// Creates a pre-configured actor for custom user scenario
  static func customUser(_ name: String) -> MockGoogleOAuthRepository {
    MockGoogleOAuthRepository(configuration: .customUser(name))
  }

  /// Creates a pre-configured actor for network error scenario
  static func networkError() -> MockGoogleOAuthRepository {
    MockGoogleOAuthRepository(configuration: .networkError)
  }

  /// Creates a pre-configured actor with custom delay
  static func withDelay(_ delay: TimeInterval) -> MockGoogleOAuthRepository {
    MockGoogleOAuthRepository(configuration: .customDelay(delay))
  }
}

// MARK: - Mock Errors

public enum MockGoogleOAuthError: Error, LocalizedError {
  case signInFailed
  case networkError
  case invalidCredentials
  case userCancelled
  case unknownError

  public var errorDescription: String? {
    switch self {
    case .signInFailed:
      "Mock Google OAuth sign in failed"
    case .networkError:
      "Mock Google OAuth network error"
    case .invalidCredentials:
      "Mock Google OAuth invalid credentials"
    case .userCancelled:
      "Mock Google OAuth user cancelled"
    case .unknownError:
      "Mock Google OAuth unknown error"
    }
  }
}
