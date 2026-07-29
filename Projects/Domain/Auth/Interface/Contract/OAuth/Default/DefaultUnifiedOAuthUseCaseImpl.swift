//
//  DefaultUnifiedOAuthUseCaseImpl.swift
//  DomainInterface
//

@preconcurrency import AuthenticationServices
import Entity
import Foundation

/// 통합 OAuth UseCase 의 기본 구현체 (테스트 / 프리뷰용 no-op)
public final class DefaultUnifiedOAuthUseCaseImpl: UnifiedOAuthUseCaseInterface, @unchecked Sendable {
  public init() {}

  public func processOAuthFlow(
    with _: SocialType,
    appleCredential _: ASAuthorizationAppleIDCredential?,
    nonce _: String?,
    googleToken _: String?,
    kakaoToken _: String?
  ) async -> Result<LoginEntity, AuthError> {
    .failure(.unknownError("DefaultUnifiedOAuthUseCaseImpl"))
  }
}
