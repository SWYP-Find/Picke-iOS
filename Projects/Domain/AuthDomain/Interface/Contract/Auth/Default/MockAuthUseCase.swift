//
//  MockAuthUseCase.swift
//  DomainInterface
//

import Foundation

/// Auth UseCase 의 기본 구현체 (테스트 / 프리뷰용 no-op)
public final class MockAuthUseCase: AuthUseCaseInterface, @unchecked Sendable {
  public init() {}

  public func login(
    provider: SocialType,
    authorizationCode _: String,
    redirectUri _: String?,
    idToken _: String?
  ) async throws -> LoginEntity {
    LoginEntity(
      name: "Mock User",
      isNewUser: false,
      provider: provider,
      token: AuthTokens(
        accessToken: "mock_access_token_\(UUID().uuidString)",
        refreshToken: "mock_refresh_token_\(UUID().uuidString)"
      ),
      userTag: "mock_tag",
      status: "active"
    )
  }

  public func refresh() async throws -> AuthTokens {
    AuthTokens(
      accessToken: "mock_refreshed_access_token_\(UUID().uuidString)",
      refreshToken: "mock_refreshed_refresh_token_\(UUID().uuidString)"
    )
  }

  public func withDraw(reason _: String) async throws -> WithdrawEntity {
    WithdrawEntity(isSuccess: true)
  }

  public func logout() async throws -> AuthExitEntity {
    AuthExitEntity(
      loggedOut: true,
      code: "200",
      message: "로그아웃이 성공적으로 완료되었습니다.",
      detail: "사용자 세션이 종료되었습니다."
    )
  }

  public func updateSessionCredential(with _: AuthTokens) {
    // no-op
  }
}
