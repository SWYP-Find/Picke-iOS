//
//  UnifiedOAuthUseCaseInterface.swift
//  DomainInterface
//
//  통합 OAuth UseCase 인터페이스 + 의존성 등록.
//  구현(UnifiedOAuthUseCase)은 UseCase 모듈에 유지하고 DI 로 주입한다.
//

@preconcurrency import AuthenticationServices
import Entity
import Foundation
import WeaveDI

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
public struct UnifiedOAuthUseCaseDependency: DependencyKey {
  public static var liveValue: UnifiedOAuthUseCaseInterface {
    return UnifiedDI.resolve(UnifiedOAuthUseCaseInterface.self) ?? DefaultUnifiedOAuthUseCaseImpl()
  }

  public static var testValue: UnifiedOAuthUseCaseInterface {
    return UnifiedDI.resolve(UnifiedOAuthUseCaseInterface.self) ?? DefaultUnifiedOAuthUseCaseImpl()
  }

  public static var previewValue: UnifiedOAuthUseCaseInterface = liveValue
}

public extension DependencyValues {
  var unifiedOAuthUseCase: UnifiedOAuthUseCaseInterface {
    get { self[UnifiedOAuthUseCaseDependency.self] }
    set { self[UnifiedOAuthUseCaseDependency.self] = newValue }
  }
}
