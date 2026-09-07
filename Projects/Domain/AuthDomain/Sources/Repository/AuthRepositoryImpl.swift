//
//  AuthRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

import APIEndpoint
import AuthDomainInterface
import PickeAuthInterface
import PickeNetwork

import Dependencies
import LogMacro

public final class AuthRepositoryImpl: AuthInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client
  @Dependency(\.authService) private var authService

  public init() {}

  // MARK: - 로그인

  public func login(
    provider socialProvider: SocialType,
    authorizationCode: String,
    redirectUri: String?,
    idToken: String?
  ) async throws -> LoginEntity {
    let body = OAuthLoginRequest(
      authorizationCode: authorizationCode,
      redirectUri: redirectUri,
      idToken: idToken
    )
    if let data = try? JSONEncoder().encode(body),
       let json = String(data: data, encoding: .utf8)
    {
      Log.debug("[AuthRepository] POST /api/v1/auth/login/\(socialProvider.rawValue) body=\(json)")
    }

    let data = try await client.send(
      AuthService.login(provider: socialProvider, body: body),
      as: LoginDataDTO.self
    )

    return data.toDomain(provider: socialProvider)
  }

  // MARK: - 토큰 재발급

  public func refresh() async throws -> AuthTokens {
    let refreshToken = await authService.refreshToken ?? ""

    do {
      let data = try await client.send(
        AuthService.refresh(refreshToken: refreshToken),
        as: TokenDTO.self
      )
      return data.toDomain()
    } catch {
      Log.error("🔍 [AuthRepositoryImpl] Refresh failed: \(error)")

      // 서버가 refresh token 을 거부한 경우만 재로그인으로 보낸다(5xx 는 일시 장애).
      if case let .response(response) = error, response.isUnauthorized {
        throw AuthError.refreshTokenExpired
      }
      throw error
    }
  }

  // MARK: - 로그아웃

  public func logout() async throws -> AuthExitEntity {
    let response = try await client.sendResponse(AuthService.logout)
    let decoder = JSONDecoder()

    if (200 ... 299).contains(response.statusCode) {
      await authService.signOut()
      if response.data.isEmpty { return AuthExitEntity(loggedOut: true) }
      if let success = try? decoder.decode(LogOutDTO.self, from: response.data) {
        return success.toDomain()
      }
      return AuthExitEntity(loggedOut: true)
    }

    if let errorDTO = try? decoder.decode(LogOutDTO.self, from: response.data) {
      return errorDTO.toDomain()
    }
    return AuthExitEntity(message: String(data: response.data, encoding: .utf8))
  }

  // MARK: - 회원 탈퇴

  public func withDraw(reason: String) async throws -> WithdrawEntity {
    let response = try await client.sendResponse(AuthService.withdraw(reason: reason))
    let decoder = JSONDecoder()

    if (200 ... 299).contains(response.statusCode) {
      if response.data.isEmpty { return WithdrawEntity(isSuccess: true, withdrawn: true) }
      if let success = try? decoder.decode(WithdrawDTO.self, from: response.data) {
        return success.toDomain(isSuccess: true)
      }
      return WithdrawEntity(isSuccess: true, withdrawn: true)
    }

    if let errorDTO = try? decoder.decode(WithdrawDTO.self, from: response.data) {
      return errorDTO.toDomain(isSuccess: false)
    }
    return WithdrawEntity(
      isSuccess: false,
      message: String(data: response.data, encoding: .utf8)
    )
  }

  // MARK: - 세션 Credential 업데이트

  /// 로그인 토큰을 Keychain 과 실행 중인 인증 세션에 함께 반영한다.
  public func updateSessionCredential(with tokens: AuthTokens) async {
    await authService.signIn(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken
    )
  }
}
