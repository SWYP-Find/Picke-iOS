//
//  KakaoOAuthRepository.swift
//  Data
//
//  Created by Wonji Suh  on 12/05/25.
//

import AuthenticationServices
import CryptoKit
import DomainInterface
import Entity
import Foundation
import LogMacro
import Security
import UIKit

/// Kakao OAuth - 백엔드 콜백 기반(PKCE) 플로우
/// 1) authorize 호출 (카카오톡/웹)
/// 2) 서버 콜백 → 앱 딥링크(sseudam://oauth/kakao?ticket=...)
/// 3) ticket + code_verifier/redirectUri를 전달해 서버에서 토큰 교환
@MainActor
public final class KakaoOAuthRepository: NSObject, KakaoOAuthInterface {
  public struct StatePayload: Codable {
    let codeVerifier: String
    let appRedirectUri: String
  }

  public struct PKCE {
    let codeVerifier: String
    let codeChallenge: String
  }

  /// 백엔드와 카카오 OAuth 양쪽에 등록된 redirect URI
  /// (`/api/v1/auth/login/kakao` 의 `redirectUri` 필드와 동일 값)
  private let serverRedirectUri = "https://picke.store/oauth/kakao"
  private let appRedirectUri = "picke://oauth/kakao"
  private var authSession: ASWebAuthenticationSession?
  private let presentationContextProvider: ASWebAuthenticationPresentationContextProviding

  public init(presentationContextProvider: ASWebAuthenticationPresentationContextProviding) {
    self.presentationContextProvider = presentationContextProvider
  }

  deinit {
    // Repository 해제 시 세션도 함께 정리
    authSession?.cancel()
    authSession = nil
  }

  public func signIn() async throws -> KakaoOAuthPayload {
    // 이전 시도에서 남은 코드를 제거하고 새 플로우 시작
    await KakaoAuthCodeStore.shared.reset()

    // 기존 인증 세션이 있으면 정리
    await cancelExistingSession()

    let pkce = try generatePKCE()
    let state = try encodeState(
      StatePayload(codeVerifier: pkce.codeVerifier, appRedirectUri: appRedirectUri)
    )

    // Kakao 웹 인증에는 REST API 키를 사용한다. (네이티브 키가 아님)
    guard let clientID = Bundle.main.object(forInfoDictionaryKey: "KAKAO_REST_API_KEY") as? String,
          !clientID.isEmpty
    else {
      throw AuthError.configurationMissing
    }

    let authorizeURL = try buildAuthorizeURL(
      clientID: clientID,
      codeChallenge: pkce.codeChallenge,
      state: state
    )

    // 카카오톡 설치 시: 톡 앱으로만 진행(웹 세션 표시 없음), 딥링크(ticket/code)는 KakaoAuthCodeStore에서 기다림
    if let talkURL = talkAuthorizeURL(from: authorizeURL) {
      UIApplication.shared.open(talkURL, options: [:], completionHandler: nil)

      do {
        let ticket = try await KakaoAuthCodeStore.shared.waitForCode()
        return KakaoOAuthPayload(
          idToken: "",
          accessToken: "",
          refreshToken: nil,
          authorizationCode: ticket,
          displayName: nil,
          codeVerifier: pkce.codeVerifier,
          redirectUri: serverRedirectUri
        )
      } catch {
        // 카카오톡 인증 실패 시 정리
        await KakaoAuthCodeStore.shared.reset()
        throw error
      }
    }

    // 카카오톡 미설치: 웹 authorize (ASWebAuthenticationSession)
    do {
      let ticket = try await startAuthSession(with: authorizeURL, callbackScheme: URL(string: appRedirectUri)?.scheme)

      return KakaoOAuthPayload(
        idToken: "",
        accessToken: "",
        refreshToken: nil,
        authorizationCode: ticket, // ticket 혹은 code를 authorizationCode로 전달
        displayName: nil,
        codeVerifier: pkce.codeVerifier, // 서버 토큰 교환 시 사용
        redirectUri: serverRedirectUri // 서버 콜백 URI
      )
    } catch {
      // 웹 인증 실패 시 세션 정리
      await cleanupSession()
      throw error
    }
  }
}

// MARK: - Private helpers

private extension KakaoOAuthRepository {
  func generatePKCE() throws -> PKCE {
    let verifierData = try randomData(length: 48)
    let verifier = base64URLEncode(verifierData)
    guard let challengeData = verifier.data(using: .utf8) else {
      throw AuthError.unknownError("PKCE 생성 실패")
    }
    let challengeHash = SHA256.hash(data: challengeData)
    let challenge = base64URLEncode(Data(challengeHash))
    return PKCE(codeVerifier: verifier, codeChallenge: challenge)
  }

  func encodeState(_ payload: StatePayload) throws -> String {
    let data = try JSONEncoder().encode(payload)
    return base64URLEncode(data)
  }

  func buildAuthorizeURL(
    clientID: String,
    codeChallenge: String,
    state: String
  ) throws -> URL {
    var components = URLComponents(string: "https://kauth.kakao.com/oauth/authorize")
    components?.queryItems = [
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: serverRedirectUri),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "prompt", value: "login"), // 계정 선택 강제
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
      URLQueryItem(name: "state", value: state),
    ]
    guard let url = components?.url else {
      throw AuthError.invalidCredential("Kakao authorize URL 생성 실패")
    }
    return url
  }

  func talkAuthorizeURL(from authorizeURL: URL) -> URL? {
    guard var components = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false) else { return nil }
    components.scheme = "kakaokompassauth"
    guard let talkURL = components.url else { return nil }
    return UIApplication.shared.canOpenURL(talkURL) ? talkURL : nil
  }

  func startAuthSession(
    with url: URL,
    callbackScheme: String?
  ) async throws -> String {
    // 기존 세션이 있으면 정리
    await cancelExistingSession()

    return try await withCheckedThrowingContinuation { [weak self] continuation in
      guard let self else {
        continuation.resume(throwing: AuthError.unknownError("Repository가 해제되었습니다"))
        return
      }

      // 한 번만 호출되도록 보장하는 래퍼
      var isResumed = false
      let safeResume: (Result<String, Error>) -> Void = { [weak self] result in
        guard !isResumed else { return }
        isResumed = true

        Task { @MainActor [weak self] in
          guard let self else { return }
          authSession = nil

          switch result {
          case let .success(ticket):
            continuation.resume(returning: ticket)
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
          safeResume(.failure(AuthError.unknownError("Kakao 로그인 콜백이 없습니다")))
          return
        }

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
          safeResume(.failure(AuthError.invalidCredential("잘못된 Kakao 콜백 URL")))
          return
        }

        if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
          safeResume(.failure(AuthError.unknownError(error)))
          return
        }

        let ticket = components.queryItems?.first(where: { $0.name == "ticket" })?.value
          ?? components.queryItems?.first(where: { $0.name == "code" })?.value

        guard let ticket else {
          safeResume(.failure(AuthError.unknownError("Kakao ticket을 찾을 수 없습니다")))
          return
        }

        safeResume(.success(ticket))
      }

      session.presentationContextProvider = presentationContextProvider
      session.prefersEphemeralWebBrowserSession = true

      authSession = session
      if !session.start() {
        safeResume(.failure(AuthError.unknownError("세션 시작에 실패했습니다")))
      }
    }
  }

  /// 기존 세션을 안전하게 취소
  private func cancelExistingSession() async {
    if let session = authSession {
      session.cancel()
    }
    authSession = nil
  }

  /// 세션 정리
  private func cleanupSession() async {
    authSession = nil
  }

  func randomData(length: Int) throws -> Data {
    var data = Data(count: length)
    let result = data.withUnsafeMutableBytes {
      SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
    }
    guard result == errSecSuccess else {
      throw AuthError.unknownError("난수 생성 실패")
    }
    return data
  }

  func base64URLEncode(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}

// MARK: - Helpers
