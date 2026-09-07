//
//  PieckeDomainTests.swift
//  APITests
//

import Testing

@testable import API
import PickeNetworkInterface

struct PieckeDomainTests {
  @Test
  func 모든_도메인_경로는_api_v1_아래에_있다() {
    for domain in [
      PieckeDomain.attendance, .auth, .profile, .home, .poll,
      .battle, .comment, .perspective, .search, .notification, .device,
    ] {
      #expect(domain.url.hasPrefix("api/v1/"))
    }
  }

  @Test
  func 도메인마다_서로_다른_경로를_쓴다() {
    let urls = [
      PieckeDomain.attendance, .auth, .profile, .home, .poll,
      .battle, .comment, .perspective, .search, .notification, .device,
    ].map(\.url)

    #expect(Set(urls).count == urls.count)
  }

  @Test
  func baseURL_은_https_스킴을_붙여_만든다() {
    #expect(PieckeDomain.auth.baseURLString.hasPrefix("https://"))
  }
}
