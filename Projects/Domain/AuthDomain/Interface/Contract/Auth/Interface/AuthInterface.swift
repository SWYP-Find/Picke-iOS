//
//  AuthInterface.swift
//  DomainInterface
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation
import ComposableArchitecture

/// Auth 관련 비즈니스 로직을 위한 Interface 프로토콜
public protocol AuthInterface: Sendable {
  func login(
    provider: SocialType,
    authorizationCode: String,
    redirectUri: String?,
    idToken: String?
  ) async throws -> LoginEntity
  func refresh() async throws -> AuthTokens
  func withDraw(reason: String) async throws -> WithdrawEntity
  func logout() async throws -> AuthExitEntity
  func updateSessionCredential(with tokens: AuthTokens) async
}

/// Auth Repository 의 DependencyKey 구조체
public enum AuthRepositoryDependency: TestDependencyKey {
  public static var testValue: AuthInterface { MockAuthRepository() }
}

public extension DependencyValues {
  var authRepository: AuthInterface {
    get { self[AuthRepositoryDependency.self] }
    set { self[AuthRepositoryDependency.self] = newValue }
  }
}
