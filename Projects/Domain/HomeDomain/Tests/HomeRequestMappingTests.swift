//
//  HomeRequestMappingTests.swift
//  HomeDataTests
//

import Foundation
import Testing

@testable import HomeData

import APIEndpoint
import NetworkHeader

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

  @Test func home_요청은_baseHeader_를_포함한다() throws {
    let request = try HomeService.home.asURLRequest()

    #expect(request.value(forHTTPHeaderField: "Content-Type") != nil)
    #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer") == true)
  }
}
