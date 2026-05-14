//
//  AuthInterceptor.swift
//  Repository
//
//  Created by Wonji Suh on 5/14/26.
//

import Alamofire
import ComposableArchitecture
import Dependencies
import DomainInterface
import Entity
import Foundation
import LogMacro
import Moya
import UIKit

// MARK: - Notification

public extension NSNotification.Name {
  /// 리프레시 토큰 만료 시 발송되는 알림
  static let refreshTokenExpired = NSNotification.Name("PickeRefreshTokenExpired")
}

// MARK: - Token Refresh Manager

actor TokenRefreshManager {
  @Dependency(\.authRepository) private var authRepository
  @Dependency(\.keychainManager) private var keychainManager

  private var isRefreshing = false

  func refreshCredentialIfNeeded() async throws -> AccessTokenCredential {
    if isRefreshing {
      try await _Concurrency.Task.sleep(nanoseconds: 100_000_000)
      return try await refreshCredentialIfNeeded()
    }

    isRefreshing = true
    defer { isRefreshing = false }

    return try await performTokenRefresh()
  }

  private func performTokenRefresh() async throws -> AccessTokenCredential {
    Log.debug("🔄 Starting token refresh...")

    do {
      let tokens = try await authRepository.refresh()
      Log.debug("✅ Token refresh completed: \(tokens)")

      keychainManager.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)

      let newCredential = AccessTokenCredential.make(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken
      )

      await MainActor.run {
        AuthSessionManager.shared.credential = newCredential
        OptimizedSessionManager.shared.credential = newCredential
      }

      return newCredential
    } catch {
      Log.error("❌ Token refresh failed: \(error)")

      if isRefreshTokenExpiredError(error) {
        await performAutomaticLogout()
        throw AuthError.refreshTokenExpired
      } else {
        throw error
      }
    }
  }

  private func isRefreshTokenExpiredError(_ error: Error) -> Bool {
    let errorString = String(describing: error)
    if errorString.contains("statusCodeError(401)") { return true }

    if let moyaError = error as? MoyaError {
      switch moyaError {
      case let .statusCode(response):
        if response.statusCode == 401 { return true }
      case let .underlying(_, response):
        if response?.statusCode == 401 { return true }
      default:
        break
      }
    }

    if let authError = error as? AuthError, authError.isTokenExpiredError {
      return true
    }

    let desc = error.localizedDescription.lowercased()
    return desc.contains("401")
      || desc.contains("unauthorized")
      || desc.contains("token expired")
      || desc.contains("invalid token")
  }

  private func performAutomaticLogout() async {
    Log.debug("🚪 Performing automatic logout (401 detected)")

    keychainManager.clear()

    await MainActor.run {
      AuthSessionManager.shared.credential = nil
      OptimizedSessionManager.shared.credential = nil

      NotificationCenter.default.post(
        name: .refreshTokenExpired,
        object: nil,
        userInfo: ["reason": "401_refresh_failed"]
      )
    }
  }
}

// MARK: - Auth Interceptor

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
  private let tokenRefreshManager = TokenRefreshManager()

  func adapt(
    _ urlRequest: URLRequest,
    for _: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    var adapted = urlRequest

    guard let credential = OptimizedSessionManager.shared.credential else {
      completion(.success(urlRequest))
      return
    }

    if credential.requiresRefresh {
      _Concurrency.Task {
        do {
          let newCredential = try await tokenRefreshManager.refreshCredentialIfNeeded()
          adapted.headers.update(.authorization(bearerToken: newCredential.accessToken))
          completion(.success(adapted))
        } catch {
          Log.error("❌ Token refresh failed in adapt: \(error)")
          completion(.failure(error))
        }
      }
    } else {
      adapted.headers.update(.authorization(bearerToken: credential.accessToken))
      completion(.success(adapted))
    }
  }

  func retry(
    _ request: Request,
    for _: Session,
    dueTo error: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    guard let response = request.response, response.statusCode == 401 else {
      completion(.doNotRetryWithError(error))
      return
    }

    Log.debug("🚨 401 detected, attempting token refresh for retry")

    _Concurrency.Task {
      do {
        _ = try await tokenRefreshManager.refreshCredentialIfNeeded()
        completion(.retry)
      } catch {
        if let authError = error as? AuthError, authError.isTokenExpiredError {
          completion(.doNotRetryWithError(authError))
        } else {
          completion(.doNotRetryWithError(error))
        }
      }
    }
  }
}
