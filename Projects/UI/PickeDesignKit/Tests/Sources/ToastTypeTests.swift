//
//  ToastTypeTests.swift
//  PickeDesignKitTests
//

import Testing

@testable import PickeDesignKit

struct ToastTypeTests {
  private let toasts: [ToastType] = [
    .success("성공"),
    .error("실패"),
    .warning("주의"),
    .info("안내"),
    .loading("불러오는 중"),
  ]

  @Test
  func message_는_어떤_종류든_연관값을_꺼낸다() {
    #expect(toasts.map(\.message) == ["성공", "실패", "주의", "안내", "불러오는 중"])
  }

  /// 로딩만 아이콘 대신 인디케이터를 그린다.
  @Test
  func 로딩_토스트만_아이콘이_없다() {
    #expect(ToastType.loading("불러오는 중").iconName == nil)

    let others = toasts.filter { $0 != .loading("불러오는 중") }
    #expect(others.count == 4)
    #expect(others.allSatisfy { $0.iconName != nil })
  }

  @Test
  func 같은_종류_같은_문구면_같은_토스트다() {
    #expect(ToastType.success("완료") == .success("완료"))
    #expect(ToastType.success("완료") != .info("완료"))
  }
}
