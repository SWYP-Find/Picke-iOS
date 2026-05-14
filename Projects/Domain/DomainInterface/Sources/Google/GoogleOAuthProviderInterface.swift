//
//  GoogleOAuthProviderInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh  on 12/29/25.
//

import Entity
import Foundation
import WeaveDI

/// Google OAuth Provider Interface 프로토콜
public protocol GoogleOAuthProviderInterface: Sendable {
  func signInWithToken(token: String) async throws -> GoogleOAuthPayload
}

/// Google OAuth Provider 의 DependencyKey 구조체
public struct GoogleOAuthProviderDependency: DependencyKey {
  public static var liveValue: GoogleOAuthProviderInterface {
    UnifiedDI.resolve(GoogleOAuthProviderInterface.self) ?? MockGoogleOAuthProvider()
  }

  public static var testValue: GoogleOAuthProviderInterface {
    UnifiedDI.resolve(GoogleOAuthProviderInterface.self) ?? MockGoogleOAuthProvider()
  }

  public static var previewValue: GoogleOAuthProviderInterface = testValue
}

public extension DependencyValues {
  var googleOAuthProvider: GoogleOAuthProviderInterface {
    get { self[GoogleOAuthProviderDependency.self] }
    set { self[GoogleOAuthProviderDependency.self] = newValue }
  }
}

/// 테스트용 Mock 구현체
public struct MockGoogleOAuthProvider: GoogleOAuthProviderInterface {
  public init() {}

  public func signInWithToken(token _: String) async throws -> GoogleOAuthPayload {
    GoogleOAuthPayload(
      idToken: "mock_google_id_token",
      accessToken: "mock_google_access_token",
      authorizationCode: "mock_google_auth_code",
      displayName: "Mock Google User",
      redirectUri: "https://picke.store/oauth/google"
    )
  }
}
