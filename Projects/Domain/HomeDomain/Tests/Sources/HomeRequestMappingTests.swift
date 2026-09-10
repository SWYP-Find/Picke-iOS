//
//  HomeRequestMappingTests.swift
//  HomeDataTests
//

import Foundation
import Testing

@testable import HomeDomain

import APIEndpoint
@testable import PickeNetwork

struct HomeRequestMappingTests {
  @Test func home_요청은_GET_이며_경로가_api_v1_home_이다() throws {
    let request = try HomeService.home.asURLRequest()

    #expect(request.url?.path == "/api/v1/home")
    #expect(request.httpMethod == "GET")
  }

  @Test func home_요청은_파라미터가_없다() throws {
    let request = try HomeService.home.asURLRequest()

    #expect(request.url?.query == nil)
    #expect(request.httpBody == nil)
  }

  @Test func home_요청은_자동_인증_정책을_사용한다() {
    #expect(HomeService.home.authorization == .automatic)
  }
}
