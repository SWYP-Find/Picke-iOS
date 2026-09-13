//
//  AdTests.swift
//  AdTests
//

import Foundation
@testable import PickeNetwork
@testable import AdDomain
import AdDomainInterface
import APIEndpoint
import Testing

struct AdDomainTests {
  @Test func 광고_DTO를_도메인으로_매핑한다() {
    let dto = FeedAdDTO(
      code: "a1",
      network: "ADPICK",
      title: "상품",
      subtitle: "상점 · 2.8%",
      imageUrl: "https://example.com/image.jpg",
      ctaText: "구매하러 가기",
      clickUrl: "https://ad.picke.store/c/a1",
      label: "광고"
    )

    #expect(dto.toDomain() == FeedAd(
      code: "a1",
      network: "ADPICK",
      title: "상품",
      subtitle: "상점 · 2.8%",
      imageURL: "https://example.com/image.jpg",
      ctaText: "구매하러 가기",
      clickURL: "https://ad.picke.store/c/a1",
      label: "광고"
    ))
  }

  @Test func 광고_조회_요청을_매핑한다() throws {
    let request = try AdsService.list(query: AdsQueryRequest()).asURLRequest()
    #expect(request.url?.path == "/api/v1/ads")
    #expect(request.httpMethod == "GET")
    #expect(request.url?.query?.contains("slot=HOME_FEED") == true)
    #expect(request.url?.query?.contains("os=IOS") == true)
    #expect(request.url?.query?.contains("size=20") == true)
  }

  @Test func 광고_노출은_codes_JSON을_POST한다() throws {
    let request = try AdsService.impressions(
      body: AdsImpressionsRequest(codes: ["first", "second"])
    ).asURLRequest()
    #expect(request.url?.path == "/api/v1/ads/impressions")
    #expect(request.httpMethod == "POST")
    let data = try #require(request.httpBody)
    let body = try JSONDecoder().decode([String: [String]].self, from: data)
    #expect(body == ["codes": ["first", "second"]])
  }
}
