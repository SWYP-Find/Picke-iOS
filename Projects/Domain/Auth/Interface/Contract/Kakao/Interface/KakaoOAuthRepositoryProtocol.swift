//
//  KakaoOAuthRepositoryProtocol.swift
//  Domain
//
//  Created by Assistant on 12/4/25.
//

import Dependencies
import Foundation
import ComposableArchitecture

public protocol KakaoOAuthInterface: Sendable {
  func signIn() async throws -> KakaoOAuthPayload
}

// MARK: - Dependencies

public enum KakaoOAuthRepositoryDependencyKey: TestDependencyKey {
  public static var testValue: KakaoOAuthInterface { MockKakaoOAuthRepository() }
}

public extension DependencyValues {
  var kakaoOAuthRepository: KakaoOAuthInterface {
    get { self[KakaoOAuthRepositoryDependencyKey.self] }
    set { self[KakaoOAuthRepositoryDependencyKey.self] = newValue }
  }
}
