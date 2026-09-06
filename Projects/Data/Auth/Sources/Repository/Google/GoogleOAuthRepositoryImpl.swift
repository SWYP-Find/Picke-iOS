//
//  GoogleOAuthRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 12/29/25.
//

import AuthDomainInterface
import AuthenticationServices
import Foundation
import LogMacro
import UIKit

/// Google OAuth — WKWebView 로 authorize URL 띄우고 redirect 콜백을 navigation 단계에서 가로채는 흐름.
/// 1)
/// `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&redirect_uri={BASE_URL}/oauth/google&...`
/// 2) 사용자 동의 → 구글이 `{BASE_URL}/oauth/google?code=...` 로 리다이렉트 시도
/// 3) WKWebView 가 해당 URL 로 이동하기 전에 navigation 을 cancel 하고 `code` 만 추출
///    (서버 401 응답은 송신되지 않고 사용자에게도 노출되지 않음)
@MainActor
public final class GoogleOAuthRepositoryImpl: NSObject, GoogleOAuthInterface {
  private let redirectPath = "/oauth/google"
  private let scope = "email profile"
  private var serverRedirectUri: String { OAuthRedirectConfiguration.redirectURI(path: redirectPath) }
  private var redirectHost: String { OAuthRedirectConfiguration.redirectHost }

  /// DI 호환을 위해 유지 (WKWebView 기반에서는 미사용)
  private let presentationContextProvider: ASWebAuthenticationPresentationContextProviding

  /// 저장 프로퍼티 대입만 하므로 격리가 필요 없다.
  /// DependencyKey 의 nonisolated `liveValue` 에서 생성된다.
  public nonisolated init(presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
    self.presentationContextProvider = presentationContextProvider
  }

  public func signIn() async throws -> GoogleOAuthPayload {
    guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
          !clientID.isEmpty
    else {
      throw AuthError.configurationMissing
    }

    let authorizeURL = try buildAuthorizeURL(clientID: clientID)
    Log.debug("google authorize", authorizeURL.absoluteString)

    let code = try await OAuthWebPresenter.present(
      authorizeURL: authorizeURL,
      redirectHost: redirectHost,
      redirectPath: redirectPath,
      customUserAgent: OAuthWebUserAgent.mobileSafari
    )
    Log.debug("google authorizationCode", code)

    return GoogleOAuthPayload(
      idToken: "",
      accessToken: nil,
      authorizationCode: code,
      displayName: nil,
      redirectUri: serverRedirectUri
    )
  }
}

private extension GoogleOAuthRepositoryImpl {
  func buildAuthorizeURL(clientID: String) throws -> URL {
    var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
    components?.queryItems = [
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: serverRedirectUri),
      URLQueryItem(name: "scope", value: scope),
      URLQueryItem(name: "prompt", value: "select_account"),
      URLQueryItem(name: "access_type", value: "offline"),
    ]
    guard let url = components?.url else {
      throw AuthError.invalidCredential("Google authorize URL 생성 실패")
    }
    return url
  }
}
