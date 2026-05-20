//
//  KakaoOAuthRepositoryProtocol.swift
//  Domain
//
//  Created by Assistant on 12/4/25.
//

import Dependencies
import Entity
import Foundation
import WeaveDI

public protocol KakaoOAuthInterface: Sendable {
  func signIn() async throws -> KakaoOAuthPayload
}

// MARK: - Dependencies

public struct KakaoOAuthRepositoryDependencyKey: DependencyKey {
  public static var liveValue: KakaoOAuthInterface {
    return UnifiedDI.resolve(KakaoOAuthInterface.self) ?? MockKakaoOAuthRepository()
  }

  public static var previewValue: KakaoOAuthInterface = MockKakaoOAuthRepository()
  public static var testValue: KakaoOAuthInterface = MockKakaoOAuthRepository()
}

public extension DependencyValues {
  var kakaoOAuthRepository: KakaoOAuthInterface {
    get { self[KakaoOAuthRepositoryDependencyKey.self] }
    set { self[KakaoOAuthRepositoryDependencyKey.self] = newValue }
  }
}
