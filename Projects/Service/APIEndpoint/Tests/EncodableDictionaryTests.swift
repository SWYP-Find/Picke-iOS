//
//  EncodableDictionaryTests.swift
//  APIEndpointTests
//

import Foundation
import Testing

@testable import APIEndpoint

struct EncodableDictionaryTests {
  private struct Payload: Encodable {
    let reason: String
    let count: Int
  }

  @Test
  func Encodable_을_파라미터_딕셔너리로_바꾼다() throws {
    let dictionary = try #require(Payload(reason: "이유", count: 2).toDictionary)

    #expect(dictionary["reason"] as? String == "이유")
    #expect(dictionary["count"] as? Int == 2)
  }

  /// URL 이 `https:\/\/` 로 이스케이프되면 서버 로그와 대조가 어려워 옵션을 꺼 뒀다.
  @Test
  func 슬래시를_이스케이프하지_않는다() throws {
    let dictionary = try #require(Payload(reason: "https://picke.io/a", count: 0).toDictionary)

    #expect(dictionary["reason"] as? String == "https://picke.io/a")
  }

  @Test
  func 스칼라를_지정한_키의_딕셔너리로_감싼다() {
    #expect("값".toDictionary(key: "reason")["reason"] as? String == "값")
    #expect(7.toDictionary(key: "count")["count"] as? Int == 7)
  }
}
