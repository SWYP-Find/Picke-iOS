//
//  PickeAuthTests.swift
//  PickeAuthTests
//

import Foundation
import Testing

@testable import PickeAuth
import PickeAuthTesting

struct JWTDecoderTests {
  /// `exp` 만 담은 payload 를 패딩 없는 base64url 로 만들어 실제 토큰 형태를 흉내낸다.
  private func makeToken(expiration: TimeInterval) -> String {
    let payload = try! JSONSerialization.data(withJSONObject: ["exp": expiration])
    let encoded = payload.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    return "header.\(encoded).signature"
  }

  @Test
  func decodesExpirationFromBase64URLPayload() {
    let expiration: TimeInterval = 1_800_000_000

    let date = JWTDecoder.decodeExpiration(makeToken(expiration: expiration))

    #expect(date == Date(timeIntervalSince1970: expiration))
  }

  @Test
  func returnsNilWhenSegmentsAreMissing() {
    #expect(JWTDecoder.decodeExpiration("not-a-jwt") == nil)
  }

  @Test
  func returnsNilWhenPayloadHasNoExpiration() {
    let payload = try! JSONSerialization.data(withJSONObject: ["sub": "1"])
    let encoded = payload.base64EncodedString()

    #expect(JWTDecoder.decodeExpiration("header.\(encoded).signature") == nil)
  }
}

struct StubAuthServiceTests {
  @Test
  func signOutClearsStoredTokens() async {
    let service = StubAuthService(accessToken: "a", refreshToken: "r")
    #expect(await service.isLoggedIn)

    await service.signOut()

    #expect(await service.isLoggedIn == false)
    #expect(await service.refreshToken == nil)
  }
}
