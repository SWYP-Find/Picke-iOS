//
//  UnifiedOAuthUseCase.swift
//  UseCase
//
//  Created by Wonji Suh  on 12/29/25.
//

@preconcurrency import AuthDomainInterface
import AuthenticationServices
import Dependencies
import Foundation
import LogMacro
import Sharing
import PickeStorageInterface

/// 통합 OAuth UseCase — 소셜 인증 → 백엔드 로그인까지 단일 진입점
public struct UnifiedOAuthUseCase: UnifiedOAuthUseCaseInterface {
  @Dependency(\.authRepository) private var authRepository: AuthInterface
  @Dependency(\.appleOAuthProvider) private var appleProvider: AppleOAuthProviderInterface
  @Dependency(\.googleOAuthProvider) private var googleProvider: GoogleOAuthProviderInterface
  @Dependency(\.kakaoOAuthProvider) private var kakaoProvider: KakaoOAuthProviderInterface
  @Dependency(\.keychainManager) private var keychainManager: KeychainManaging
  @Shared(.userSession) var userSession: UserSession
  @Shared(.appStorage("appleUserName")) var savedAppleUserName: String?

  public init() {}
}

// MARK: - Public Interface

public extension UnifiedOAuthUseCase {
  /// 통합 소셜 로그인 처리
  func socialLogin(
    with socialType: SocialType,
    appleCredential: ASAuthorizationAppleIDCredential? = nil,
    nonce: String? = nil,
    googleToken: String? = nil,
    kakaoToken: String? = nil
  ) async throws -> LoginEntity {
    switch socialType {
    case .apple:
      guard let credential = appleCredential, let nonce else {
        throw AuthError.invalidCredential("Apple 로그인에 필요한 credential 또는 nonce가 없습니다")
      }
      return try await appleLogin(credential: credential, nonce: nonce)

    case .google:
      guard let token = googleToken else {
        throw AuthError.invalidCredential("Google 로그인에 필요한 token이 없습니다")
      }
      return try await googleLogin(token: token)

    case .kakao:
      guard let token = kakaoToken else {
        throw AuthError.invalidCredential("Kakao 로그인에 필요한 token이 없습니다")
      }
      return try await kakaoLogin(token: token)
    }
  }

  /// Apple 로그인 처리
  func appleLogin(
    credential: ASAuthorizationAppleIDCredential,
    nonce: String
  ) async throws -> LoginEntity {
    let payload = try await appleProvider.signInWithCredential(
      credential: credential,
      nonce: nonce
    )
    Log.debug("apple authcode", payload.authorizationCode)

    let userName: String = {
      if let displayName = payload.displayName, !displayName.isEmpty {
        self.$savedAppleUserName.withLock { $0 = displayName }
        return displayName
      } else {
        return self.savedAppleUserName ?? ""
      }
    }()

    $userSession.withLock {
      $0.token = payload.authorizationCode ?? ""
      $0.accessToken = payload.idToken
      $0.oauthRefreshToken = payload.idToken
      $0.name = userName
    }

    let authCode = payload.authorizationCode ?? ""
    AuthLocalStorage.authCode = authCode
    AuthLocalStorage.idToken = payload.idToken

    let loginEntity = try await authRepository.login(
      provider: .apple,
      authorizationCode: authCode,
      redirectUri: nil,
      idToken: payload.idToken
    )

    keychainManager.save(
      accessToken: loginEntity.token.accessToken,
      refreshToken: loginEntity.token.refreshToken
    )
    await authRepository.updateSessionCredential(with: loginEntity.token)

    return loginEntity
  }

  /// Google 로그인 처리 — picke:// 콜백에서 받은 `code` 를 백엔드에 전달.
  func googleLogin(
    token: String
  ) async throws -> LoginEntity {
    let payload = try await googleProvider.signInWithToken(token: token)
    Log.debug("google authorizationCode", payload.authorizationCode)

    $userSession.withLock {
      $0.token = payload.authorizationCode ?? ""
      $0.name = payload.displayName ?? ""
      $0.provider = .google
    }

    let loginEntity = try await authRepository.login(
      provider: .google,
      authorizationCode: payload.authorizationCode ?? "",
      redirectUri: payload.redirectUri ?? SocialType.google.redirectUri,
      idToken: nil
    )

    keychainManager.save(
      accessToken: loginEntity.token.accessToken,
      refreshToken: loginEntity.token.refreshToken
    )
    await authRepository.updateSessionCredential(with: loginEntity.token)

    return loginEntity
  }

  /// Kakao 로그인 처리 — picke:// 콜백에서 받은 `code` 를 백엔드에 전달.
  func kakaoLogin(token: String) async throws -> LoginEntity {
    let payload = try await kakaoProvider.signInWithToken(token: token)
    Log.debug("kakao authorizationCode", payload.authorizationCode)

    $userSession.withLock {
      $0.token = payload.authorizationCode ?? ""
      $0.name = payload.displayName ?? ""
      $0.provider = .kakao
    }

    let loginEntity = try await authRepository.login(
      provider: .kakao,
      authorizationCode: payload.authorizationCode ?? "",
      redirectUri: payload.redirectUri ?? SocialType.kakao.redirectUri,
      idToken: nil
    )

    keychainManager.save(
      accessToken: loginEntity.token.accessToken,
      refreshToken: loginEntity.token.refreshToken
    )
    await authRepository.updateSessionCredential(with: loginEntity.token)

    return loginEntity
  }

  /// OAuth 플로우 처리 (TCA용)
  func processOAuthFlow(
    with socialType: SocialType,
    appleCredential: ASAuthorizationAppleIDCredential? = nil,
    nonce: String? = nil,
    googleToken: String? = nil,
    kakaoToken: String? = nil
  ) async -> Result<LoginEntity, AuthError> {
    do {
      let result = try await socialLogin(
        with: socialType,
        appleCredential: appleCredential,
        nonce: nonce,
        googleToken: googleToken,
        kakaoToken: kakaoToken
      )
      return .success(result)
    } catch let error as AuthError {
      return .failure(error)
    } catch {
      return .failure(.unknownError(error.localizedDescription))
    }
  }
}
