//
//  AdsServiceTests.swift
//  APIEndpointTests
//

import Testing

@testable import APIEndpoint

import Foundation
import PickeNetworkInterface

struct AdsServiceTests {
  @Test func 광고_조회_요청을_매핑한다() throws {
    let request = AdsService.list(query: AdsQueryRequest())

    #expect(try request.url().path == "/api/v1/ads")
    #expect(request.method == .get)
    let query = try #require(request.parameters as? AdsQueryRequest)
    let data = try JSONEncoder().encode(query)
    let parameters = try JSONDecoder().decode(AdsQueryParameters.self, from: data)
    #expect(parameters.slot == "HOME_FEED")
    #expect(parameters.os == "IOS")
    #expect(parameters.size == 20)
  }

  @Test func 광고_노출은_codes_JSON을_POST한다() throws {
    let request = AdsService.impressions(
      body: AdsImpressionsRequest(codes: ["first", "second"])
    )

    #expect(try request.url().path == "/api/v1/ads/impressions")
    #expect(request.method == .post)
    let body = try #require(request.parameters as? AdsImpressionsRequest)
    let data = try JSONEncoder().encode(body)
    let payload = try JSONDecoder().decode([String: [String]].self, from: data)
    #expect(payload == ["codes": ["first", "second"]])
  }
}

private struct AdsQueryParameters: Decodable {
  let slot: String
  let os: String
  let size: Int
}
