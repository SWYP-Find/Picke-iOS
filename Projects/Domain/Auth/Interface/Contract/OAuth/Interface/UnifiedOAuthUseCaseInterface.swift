//
//  UnifiedOAuthUseCaseInterface.swift
//  DomainInterface
//

@preconcurrency import AuthenticationServices
import Foundation
import ComposableArchitecture
import AuthDomainInterface

/// 통합 OAuth UseCase 를 위한 Interface 프로토콜
public protocol UnifiedOAuthUseCaseInterface: Sendable {
  /// OAuth 플로우 처리 (TCA용)
  func processOAuthFlow(
    with socialType: SocialType,
    appleCredential: ASAuthorizationAppleIDCredential?,
    nonce: String?,
    googleToken: String?,
    kakaoToken: String?
  ) async -> Result<LoginEntity, AuthError>
}

/// 통합 OAuth UseCase 의 DependencyKey 구조체
public enum UnifiedOAuthUseCaseDependency: TestDependencyKey {
  public static var testValue: UnifiedOAuthUseCaseInterface { MockUnifiedOAuthUseCase() }
}

public extension DependencyValues {
  var unifiedOAuthUseCase: UnifiedOAuthUseCaseInterface {
    get { self[UnifiedOAuthUseCaseDependency.self] }
    set { self[UnifiedOAuthUseCaseDependency.self] = newValue }
  }
}
