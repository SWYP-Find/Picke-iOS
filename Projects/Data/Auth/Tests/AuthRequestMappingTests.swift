//
//  AuthRequestMappingTests.swift
//  AuthDataTests
//

import Foundation
import Testing

@testable import AuthData

import API
import AuthDomainInterface
import NetworkHeader

struct AuthRequestMappingTests {
  // MARK: - login

  @Test
  func login_kakao_urlPath_matchesAuthAPIDescriptionPlusProvider() {
    let body = OAuthLoginRequest(
      authorizationCode: "code-kakao",
      redirectUri: "https://picke.store/oauth/kakao",
      idToken: nil
    )
    let service = AuthService.login(provider: .kakao, body: body)

    #expect(service.urlPath == "\(AuthAPI.login.description)/\(SocialType.kakao.rawValue)")
    #expect(service.urlPath == "login/kakao")
  }

  @Test
  func login_kakao_request_isPOSTWithJSONBody() throws {
    let body = OAuthLoginRequest(
      authorizationCode: "code-kakao",
      redirectUri: "https://picke.store/oauth/kakao",
      idToken: nil
    )
    let service = AuthService.login(provider: .kakao, body: body)
    let request = try service.asURLRequest()

    #expect(service.method == .post)
    #expect(request.url?.path == "/api/v1/auth/login/kakao")

    let httpBody = try #require(request.httpBody)
    let json = try #require(JSONSerialization.jsonObject(with: httpBody) as? [String: Any])
    #expect(json["authorizationCode"] as? String == "code-kakao")
    #expect(json["redirectUri"] as? String == "https://picke.store/oauth/kakao")
    #expect(json["identityToken"] == nil)
  }

  @Test
  func login_apple_request_encodesIdTokenAsIdentityTokenAndOmitsRedirectUri() throws {
    let body = OAuthLoginRequest(authorizationCode: "code-apple", redirectUri: nil, idToken: "id-token-abc")
    let service = AuthService.login(provider: .apple, body: body)
    let request = try service.asURLRequest()

    #expect(request.url?.path == "/api/v1/auth/login/apple")

    let httpBody = try #require(request.httpBody)
    let json = try #require(JSONSerialization.jsonObject(with: httpBody) as? [String: Any])
    #expect(json["authorizationCode"] as? String == "code-apple")
    #expect(json["identityToken"] as? String == "id-token-abc")
    #expect(json["redirectUri"] == nil)
  }

  @Test
  func login_request_usesNotAccessTokenHeader() throws {
    let body = OAuthLoginRequest(authorizationCode: "code", redirectUri: nil, idToken: nil)
    let service = AuthService.login(provider: .google, body: body)
    let request = try service.asURLRequest()

    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(request.value(forHTTPHeaderField: "accept") == "application/json")
    #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
  }

  // MARK: - refresh

  @Test
  func refresh_urlPath_matchesAuthAPIDescription() {
    let service = AuthService.refresh(refreshToken: "refresh-abc")

    #expect(service.urlPath == AuthAPI.refresh.description)
    #expect(service.urlPath == "refresh")
  }

  @Test
  func refresh_request_isPOSTWithNoBodyAndRefreshTokenHeader() throws {
    let service = AuthService.refresh(refreshToken: "refresh-abc")
    let request = try service.asURLRequest()

    #expect(service.method == .post)
    #expect(request.url?.path == "/api/v1/auth/refresh")
    #expect(request.httpBody == nil)
    #expect(request.value(forHTTPHeaderField: "X-Refresh-Token") == "refresh-abc")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
  }

  // MARK: - withdraw

  @Test
  func withdraw_urlPath_matchesAuthAPIDescription() {
    let service = AuthService.withdraw(reason: "NOT_USED_OFTEN")

    #expect(service.urlPath == AuthAPI.withDraw.description)
    #expect(service.urlPath == "")
  }

  @Test
  func withdraw_request_isDELETEWithJSONBodyAndBaseHeader() throws {
    let service = AuthService.withdraw(reason: "NOT_USED_OFTEN")
    let request = try service.asURLRequest()

    #expect(service.method == .delete)
    #expect(request.url?.path == "/api/v1/me")

    let httpBody = try #require(request.httpBody)
    let json = try #require(JSONSerialization.jsonObject(with: httpBody) as? [String: Any])
    #expect(json["reason"] as? String == "NOT_USED_OFTEN")

    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true)
  }

  // MARK: - logout

  @Test
  func logout_urlPath_matchesAuthAPIDescription() {
    let service = AuthService.logout

    #expect(service.urlPath == AuthAPI.logout.description)
    #expect(service.urlPath == "logout")
  }

  @Test
  func logout_request_isPOSTWithNoBodyAndBaseHeader() throws {
    let service = AuthService.logout
    let request = try service.asURLRequest()

    #expect(service.method == .post)
    #expect(request.url?.path == "/api/v1/auth/logout")
    #expect(request.httpBody == nil)
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true)
  }
}
