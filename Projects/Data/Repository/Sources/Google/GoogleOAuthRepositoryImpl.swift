//
//  GoogleOAuthRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh  on 12/29/25.
//

import AuthenticationServices
import DomainInterface
import Entity
import Foundation
import LogMacro
import UIKit

/// Google OAuth — 백엔드 API 가 redirect_uri 를 직접 처리하는 흐름.
/// 1) authorize 호출 (`https://accounts.google.com/o/oauth2/v2/auth?response_type=code...`)
///    redirect_uri = `https://picke.store/api/v1/auth/login/google`
/// 2) 구글이 백엔드 로그인 API 로 직접 콜백 (서버가 code 교환 + 토큰 발급)
/// 3) 백엔드가 `picke://oauth/google?access_token=...&refresh_token=...` 로 앱 깨움
/// 4) ASWebAuthenticationSession 가 picke:// 스킴을 가로채 토큰 추출 (POST API 호출 불필요)
@MainActor
public final class GoogleOAuthRepositoryImpl: NSObject, GoogleOAuthInterface {
  /// 구글 콘솔 / 백엔드 양쪽에 등록된 redirect URI.
  /// 백엔드가 이 콜백 핸들러 안에서 code 교환 + 로그인 처리까지 마치고
  /// `picke://oauth/google?access_token=...` 로 앱을 깨운다.
  private let serverRedirectUri = "https://picke.store/oauth/google"
  private let appRedirectUri = "picke://oauth/google"
  private let scope = "email profile"

  private var authSession: ASWebAuthenticationSession?
  private let presentationContextProvider: ASWebAuthenticationPresentationContextProviding

  public init(presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
    self.presentationContextProvider = presentationContextProvider
  }

  deinit {
    authSession?.cancel()
    authSession = nil
  }

  public func signIn() async throws -> GoogleOAuthPayload {
    await cancelExistingSession()

    guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
          !clientID.isEmpty
    else {
      throw AuthError.configurationMissing
    }

    let authorizeURL = try buildAuthorizeURL(clientID: clientID)

    do {
      let callbackURL = try await startAuthSession(
        with: authorizeURL,
        callbackScheme: URL(string: appRedirectUri)?.scheme
      )
      return try parsePayload(from: callbackURL)
    } catch {
      await cleanupSession()
      throw error
    }
  }
}

// MARK: - Private helpers

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

  /// `picke://oauth/google?code=...` 콜백에서 authorization code 추출.
  /// 추출한 code 는 백엔드 POST `/api/v1/auth/login/google` 의 `authorizationCode` 로 전달된다.
  func parsePayload(from callbackURL: URL) throws -> GoogleOAuthPayload {
    guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
      throw AuthError.invalidCredential("잘못된 Google 콜백 URL")
    }

    if let errorParam = components.queryItems?.first(where: { $0.name == "error" })?.value {
      throw AuthError.backendError(errorParam)
    }

    let query: (String) -> String? = { name in
      components.queryItems?.first(where: { $0.name == name })?.value
    }

    guard let code = query("code"), !code.isEmpty else {
      throw AuthError.unknownError("Google authorization code 를 받지 못했습니다")
    }

    return GoogleOAuthPayload(
      idToken: "",
      accessToken: nil,
      authorizationCode: code,
      displayName: query("name"),
      redirectUri: serverRedirectUri
    )
  }

  func startAuthSession(
    with url: URL,
    callbackScheme: String?
  ) async throws -> URL {
    await cancelExistingSession()

    return try await withCheckedThrowingContinuation { [weak self] continuation in
      guard let self else {
        continuation.resume(throwing: AuthError.unknownError("Repository가 해제되었습니다"))
        return
      }

      var isResumed = false
      let safeResume: (Result<URL, Error>) -> Void = { [weak self] result in
        guard !isResumed else { return }
        isResumed = true

        Task { @MainActor [weak self] in
          guard let self else { return }
          authSession = nil

          switch result {
          case let .success(url):
            continuation.resume(returning: url)
          case let .failure(error):
            continuation.resume(throwing: error)
          }
        }
      }

      let session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: callbackScheme
      ) { callbackURL, error in
        if let error {
          let nsError = error as NSError
          if nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
            safeResume(.failure(AuthError.userCancelled))
            return
          }
          safeResume(.failure(AuthError.unknownError(error.localizedDescription)))
          return
        }

        guard let callbackURL else {
          safeResume(.failure(AuthError.unknownError("Google 로그인 콜백이 없습니다")))
          return
        }

        safeResume(.success(callbackURL))
      }

      session.presentationContextProvider = presentationContextProvider
      session.prefersEphemeralWebBrowserSession = true

      authSession = session
      if !session.start() {
        safeResume(.failure(AuthError.unknownError("Google 세션 시작에 실패했습니다")))
      }
    }
  }

  func cancelExistingSession() async {
    if let session = authSession {
      session.cancel()
    }
    authSession = nil
  }

  func cleanupSession() async {
    authSession = nil
  }
}
