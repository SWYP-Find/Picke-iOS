//
//  AuthorizingInterceptorTests.swift
//  PickeNetworkTests
//

import Foundation
import Testing

@testable import PickeNetwork

import Alamofire

@Suite("AuthorizingInterceptor")
struct AuthorizingInterceptorTests {
  @Test("credential 이 있으면 Authorization Bearer 헤더를 주입한다")
  func automaticAuthorizationAddsBearerToken() async throws {
    let interceptor = makeAuthorizingInterceptor(
      credential: PickeCredential(accessToken: "access-token", refreshToken: "refresh-token")
    )
    let url = try #require(URL(string: "https://picke.test/protected"))
    let request = URLRequest(url: url)

    let adapted = try await interceptor.adapt(request, for: Session())

    #expect(adapted.value(forHTTPHeaderField: APIHeader.accessToken) == "Bearer access-token")
  }

  @Test("credential 이 없으면 Authorization 헤더를 주입하지 않는다")
  func missingCredentialSkipsBearerToken() async throws {
    let interceptor = makeAuthorizingInterceptor(credential: nil)
    let url = try #require(URL(string: "https://picke.test/public"))
    let request = URLRequest(url: url)

    let adapted = try await interceptor.adapt(request, for: Session())

    #expect(adapted.value(forHTTPHeaderField: APIHeader.accessToken) == nil)
  }

  private func makeAuthorizingInterceptor(credential: PickeCredential?) -> AuthorizingInterceptor {
    AuthorizingInterceptor(
      base: AuthenticationInterceptor(
        authenticator: PickeAuthenticator(refresher: StubTokenRefresher(), store: StubCredentialStore()),
        credential: credential
      )
    )
  }
}

private struct StubCredentialStore: CredentialStore {
  func load() -> PickeCredential? {
    nil
  }

  func save(_: PickeCredential) {}

  func clear() {}
}

private struct StubTokenRefresher: TokenRefreshing {
  func refresh(_ current: PickeCredential) async throws(PickeNetworkError) -> PickeCredential {
    current
  }
}

private extension AuthorizingInterceptor {
  func adapt(
    _ request: URLRequest,
    for session: Session
  ) async throws -> URLRequest {
    try await withCheckedThrowingContinuation { continuation in
      adapt(request, for: session) { result in
        continuation.resume(with: result)
      }
    }
  }
}
