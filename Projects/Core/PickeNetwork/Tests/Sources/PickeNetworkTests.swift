//
//  PickeNetworkTests.swift
//  PickeNetworkTests
//

import Testing

@testable import PickeNetwork

@Suite("PickeNetwork")
struct PickeNetworkTests {
  @Test("계약 헤더 상수가 재수출된다")
  func reexportsInterface() {
    #expect(APIHeader.contentType == "Content-Type")
  }
}
