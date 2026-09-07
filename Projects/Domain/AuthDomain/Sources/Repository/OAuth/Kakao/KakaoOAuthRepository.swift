//
//  KakaoOAuthRepository.swift
//  Data
//
//  Created by Wonji Suh  on 12/05/25.
//

import AuthDomainInterface
import PickeCoreLogger
import AuthenticationServices
import Foundation
import UIKit

/// Kakao OAuth — WKWebView 로 authorize URL 띄우고 redirect 콜백을 navigation 단계에서 가로채는 흐름.
/// 1) `https://kauth.kakao.com/oauth/authorize?response_type=code&redirect_uri={BASE_URL}/oauth/kakao&...`
/// 2) 사용자 동의 → 카카오가 `{BASE_URL}/oauth/kakao?code=...` 로 리다이렉트 시도
/// 3) WKWebView 가 해당 URL 로 이동하기 전에 navigation 을 cancel 하고 `code` 만 추출
///    (서버 401 응답은 송신되지 않고 사용자에게도 노출되지 않음)
@MainActor
public final class KakaoOAuthRepository: NSObject, KakaoOAuthInterface {
  private let redirectPath = "/oauth/kakao"
  private var serverRedirectUri: String { OAuthRedirectConfiguration.redirectURI(path: redirectPath) }
  private var redirectHost: String { OAuthRedirectConfiguration.redirectHost }

  /// DI 호환을 위해 유지 (WKWebView 기반에서는 미사용)
  private let presentationContextProvider: ASWebAuthenticationPresentationContextProviding

  /// 저장 프로퍼티 대입만 하므로 격리가 필요 없다.
  /// DependencyKey 의 nonisolated `liveValue` 에서 생성된다.
  public nonisolated init(presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
    self.presentationContextProvider = presentationContextProvider
  }

  public func signIn() async throws -> KakaoOAuthPayload {
    guard let clientID = Bundle.main.object(forInfoDictionaryKey: "KAKAO_REST_API_KEY") as? String,
          !clientID.isEmpty
    else {
      throw AuthError.configurationMissing
    }

    let authorizeURL = try buildAuthorizeURL(clientID: clientID)
    PickeLogger.debug("kakao authorize", authorizeURL.absoluteString, category: .auth)

    let code = try await OAuthWebPresenter.present(
      authorizeURL: authorizeURL,
      redirectHost: redirectHost,
      redirectPath: redirectPath,
      usesEphemeralSession: true
    )
    PickeLogger.debug("kakao authorizationCode", code, category: .auth)

    return KakaoOAuthPayload(
      idToken: "",
      accessToken: "",
      authorizationCode: code,
      displayName: nil,
      redirectUri: serverRedirectUri
    )
  }
}

private extension KakaoOAuthRepository {
  func buildAuthorizeURL(clientID: String) throws -> URL {
    var components = URLComponents(string: "https://kauth.kakao.com/oauth/authorize")
    components?.queryItems = [
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: serverRedirectUri),
    ]
    guard let url = components?.url else {
      throw AuthError.invalidCredential("Kakao authorize URL 생성 실패")
    }
    return url
  }
}
