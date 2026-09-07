//
//  ServerDateParserTests.swift
//  PickeCoreUtilityTests
//

import Foundation
import Testing

@testable import PickeCoreUtility

struct ServerDateParserTests {
  @Test
  func 타임존이_붙은_ISO8601_을_읽는다() throws {
    let date = try #require(ServerDateParser.parse("2026-05-22T13:28:16.697Z"))

    #expect(date.timeIntervalSince1970 == 1_779_456_496.697)
  }

  @Test
  func 소수점이_없는_ISO8601_도_읽는다() throws {
    let date = try #require(ServerDateParser.parse("2026-05-22T13:28:16Z"))

    #expect(date.timeIntervalSince1970 == 1_779_456_496)
  }

  /// 타임존 없는 LocalDateTime 이 nil 로 떨어져 모든 댓글이 "방금 전"으로 보이던 회귀 방지.
  @Test
  func 타임존이_없으면_KST_벽시계로_해석한다() throws {
    let naive = try #require(ServerDateParser.parse("2026-05-22T13:28:16"))
    let sameMoment = try #require(ServerDateParser.parse("2026-05-22T04:28:16Z"))

    #expect(naive == sameMoment)
  }

  @Test
  func 마이크로초까지_내려와도_읽는다() {
    #expect(ServerDateParser.parse("2026-05-22T13:28:16.921763") != nil)
  }

  @Test
  func 형식에_맞지_않으면_nil_이다() {
    #expect(ServerDateParser.parse("2026/05/22 13:28") == nil)
    #expect(ServerDateParser.parse("") == nil)
  }
}
