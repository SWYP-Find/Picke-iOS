//
//  AuthRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

import AuthDomainInterface
import Entity
import Model
import Service
import Repository

import Dependencies
import LogMacro
import Moya
import WeaveDI

@preconcurrency import AsyncMoya

public final class AuthRepositoryImpl: AuthInterface, @unchecked Sendable {
  @Dependency(\.keychainManager) private var keychainManager

  private let provider: any NetworkProviding<AuthService>
  private let authProvider: any NetworkProviding<AuthService>

  public init(
    provider: any NetworkProviding<AuthService> = MoyaProvider<AuthService>.default,
    authProvider: any NetworkProviding<AuthService> = MoyaProvider<AuthService>.authorized
  ) {
    self.provider = provider
    self.authProvider = authProvider
  }

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

    let dto: LoginResponseDTO = try await provider.request(
      .login(provider: socialProvider, body: body)
    )

    guard let data = dto.data else {
      let message = dto.error?.message ?? "로그인 응답이 비어 있습니다"
      throw AuthError.backendError(message)
    }

    return data.toDomain(provider: socialProvider)
  }

  // MARK: - 토큰 재발급

  public func refresh() async throws -> AuthTokens {
    let refreshToken = keychainManager.refreshToken() ?? ""

    do {
      let dto: RefreshResponseDTO = try await provider.request(.refresh(refreshToken: refreshToken))
      guard let token = dto.data else {
        let message = dto.error?.message ?? "토큰 재발급 응답이 비어 있습니다"
        throw AuthError.backendError(message)
      }
      return token.toDomain()
    } catch {
      Log.error("🔍 [AuthRepositoryImpl] Refresh failed: \(error)")

      if let moyaError = error as? MoyaError {
        switch moyaError {
        case let .statusCode(response) where response.statusCode == 401,
             let .underlying(_, response?) where response.statusCode == 401:
          throw AuthError.refreshTokenExpired
        default:
          break
        }
      }

      let errorString = String(describing: error)
      if errorString.contains("statusCodeError(401)") {
        throw AuthError.refreshTokenExpired
      }

      throw error
    }
  }

  // MARK: - 로그아웃

  public func logout() async throws -> AuthExitEntity {
    let response = try await authProvider.requestResponse(.logout)
    let decoder = JSONDecoder()

    if (200 ... 299).contains(response.statusCode) {
      clearLocalSession()
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

  public func withDraw(token: String) async throws -> WithdrawEntity {
    let response = try await authProvider.requestResponse(.withdraw(token: token))
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

  public func updateSessionCredential(with tokens: AuthTokens) {
    AuthSessionManager.shared.updateCredential(with: tokens)
    OptimizedSessionManager.shared.updateCredential(with: tokens)
  }

  private func clearLocalSession() {
    keychainManager.clear()
    AuthSessionManager.shared.clear()
    OptimizedSessionManager.shared.clear()
  }
}
