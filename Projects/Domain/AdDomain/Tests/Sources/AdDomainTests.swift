//
//  AdDomainTests.swift
//  AdDomainTests
//

import Foundation
import Testing

@testable import AdDomain

import AdDomainInterface

struct AdDomainTests {
  @Test func 광고_DTO를_도메인으로_매핑한다() {
    let dto = FeedAdDTO(
      code: "a1",
      network: "ADPICK",
      title: "상품",
      subtitle: "상점 · 2.8%",
      imageURL: "https://example.com/image.jpg",
      ctaText: "구매하러 가기",
      clickURL: "https://ad.picke.store/c/a1",
      label: "광고"
    )

    #expect(dto.toDomain() == FeedAd(
      code: "a1",
      network: "ADPICK",
      title: "상품",
      subtitle: "상점 · 2.8%",
      imageURL: URL(string: "https://example.com/image.jpg")!,
      ctaText: "구매하러 가기",
      clickURL: URL(string: "https://ad.picke.store/c/a1")!,
      label: "광고"
    ))
  }
}
