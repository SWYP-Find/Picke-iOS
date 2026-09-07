//
//  AuthServiceTests.swift
//  APIEndpointTests
//

import Testing

@testable import APIEndpoint

import API
import AuthDomainInterface
import PickeNetwork
import PickeNetworkInterface

struct AuthServiceTests {
  @Test
  func 로그인_경로에_소셜_제공자가_붙는다() {
    let sut = AuthService.login(provider: .kakao, body: .init(authorizationCode: "code", redirectUri: nil))

    #expect(sut.path == "login/kakao")
    #expect(sut.method == .post)
  }

  @Test
  func 탈퇴는_profile_도메인을_쓴다() {
    #expect(AuthService.withdraw(reason: "이유").domain.url == PieckeDomain.profile.url)
    #expect(AuthService.logout.domain.url == PieckeDomain.auth.url)
  }

  /// DELETE 인데도 바디를 보내야 해서 인코더를 따로 지정한다. 빠지면 reason 이 서버에 도달하지 않는다.
  @Test
  func 탈퇴만_JSON_바디_인코더를_지정한다() {
    #expect(AuthService.withdraw(reason: "이유").method == .delete)
    #expect(AuthService.withdraw(reason: "이유").parameterEncoder != nil)
    #expect(AuthService.logout.parameterEncoder == nil)
  }

  @Test
  func 재발급은_refresh_token_을_헤더로_보낸다() {
    let sut = AuthService.refresh(refreshToken: "refresh-token")

    #expect(sut.headers[APIHeader.refreshToken] == "refresh-token")
    #expect(sut.parameters == nil)
  }

  /// 로그인·재발급에 액세스 토큰을 붙이면 만료 상태에서 재발급 자체가 막힌다.
  @Test
  func 로그인과_재발급은_인증_파이프라인을_우회한다() {
    #expect(AuthService.login(provider: .apple, body: .init(authorizationCode: "code", redirectUri: nil)).authorization == .none)
    #expect(AuthService.refresh(refreshToken: "t").authorization == .none)
    #expect(AuthService.logout.authorization == .automatic)
    #expect(AuthService.withdraw(reason: "이유").authorization == .automatic)
  }
}
