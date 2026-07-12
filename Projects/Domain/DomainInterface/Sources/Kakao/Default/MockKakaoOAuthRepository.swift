//
//  MockKakaoOAuthRepository.swift
//  Domain
//
//  Created by Assistant on 12/4/25.
//

import Foundation
import Entity

public actor MockKakaoOAuthRepository: KakaoOAuthInterface {
  
  public enum Configuration {
    case success
    case failure
    case networkError
    case customUser(String)
    case customDelay(TimeInterval)
    
    var shouldSucceed: Bool {
      switch self {
      case .success, .customUser, .customDelay:
        return true
      case .failure, .networkError:
        return false
      }
    }
    
    var delay: TimeInterval {
      switch self {
      case .customDelay(let delay):
        return delay
      default:
        return 0.1
      }
    }
    
    var mockUserName: String {
      switch self {
      case .customUser(let name):
        return name
      default:
        return "Mock Kakao User"
      }
    }
  }
  
  private var configuration: Configuration
  private var signInCallCount = 0
  private var lastSignInCall: Date?
  
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
  
  public func signIn() async throws -> KakaoOAuthPayload {
    signInCallCount += 1
    lastSignInCall = Date()
    
    if configuration.delay > 0 {
      try await Task.sleep(for: .seconds(configuration.delay))
    }
    
    guard configuration.shouldSucceed else {
      switch configuration {
      case .failure:
        throw MockKakaoOAuthError.signInFailed
      case .networkError:
        throw MockKakaoOAuthError.networkError
      default:
        throw MockKakaoOAuthError.unknownError
      }
    }
    
    return KakaoOAuthPayload(
      idToken: "mock.kakao.idtoken.\(UUID().uuidString.prefix(8))",
      accessToken: "mock-kakao-access-token-\(UUID().uuidString.prefix(12))",
      refreshToken: "mock-kakao-refresh-token",
      authorizationCode: "mock-kakao-auth-code-\(UUID().uuidString.prefix(8))",
      displayName: configuration.mockUserName,
      codeVerifier: "mock-kakao-code-verifier-\(UUID().uuidString.prefix(8))",
      redirectUri: "https://sseudam.up.railway.app/api/v1/oauth/kakao/callback"
    )
  }
}

public enum MockKakaoOAuthError: Error, LocalizedError {
  case signInFailed
  case networkError
  case unknownError
  
  public var errorDescription: String? {
    switch self {
    case .signInFailed:
      return "Mock Kakao OAuth sign in failed"
    case .networkError:
      return "Mock Kakao OAuth network error"
    case .unknownError:
      return "Mock Kakao OAuth unknown error"
    }
  }
}
