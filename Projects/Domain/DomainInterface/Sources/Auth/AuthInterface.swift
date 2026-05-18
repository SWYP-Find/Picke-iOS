//
//  AuthInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh on 5/14/26.
//

import Entity
import Foundation
import WeaveDI

/// Auth 관련 비즈니스 로직을 위한 Interface 프로토콜
public protocol AuthInterface: Sendable {
  func login(
    provider: SocialType,
    authorizationCode: String,
    redirectUri: String?,
    idToken: String?
  ) async throws -> LoginEntity
  func refresh() async throws -> AuthTokens
  func withDraw(token: String) async throws -> WithdrawEntity
  func logout() async throws -> AuthExitEntity
  func updateSessionCredential(with tokens: AuthTokens)
}

/// Auth Repository 의 DependencyKey 구조체
public struct AuthRepositoryDependency: DependencyKey {
  public static var liveValue: AuthInterface {
    UnifiedDI.resolve(AuthInterface.self) ?? DefaultAuthRepositoryImpl()
  }

  public static var testValue: AuthInterface {
    UnifiedDI.resolve(AuthInterface.self) ?? DefaultAuthRepositoryImpl()
  }

  public static var previewValue: AuthInterface = liveValue
}

public extension DependencyValues {
  var authRepository: AuthInterface {
    get { self[AuthRepositoryDependency.self] }
    set { self[AuthRepositoryDependency.self] = newValue }
  }
}
