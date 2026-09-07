//
//  LazyViewTests.swift
//  PickeCoreUITests
//

import SwiftUI
import Testing

@testable import PickeCoreUI

@MainActor
struct LazyViewTests {
  /// TabView 가 모든 탭 콘텐츠를 즉시 만들지 않도록 막는 것이 이 래퍼의 존재 이유다.
  @Test
  func 생성_시점에는_자식_뷰를_만들지_않는다() {
    let builder = CountingViewBuilder()
    _ = LazyView { builder.make() }

    #expect(builder.count == 0)
  }

  @Test
  func body_를_평가할_때_자식_뷰를_만든다() {
    let builder = CountingViewBuilder()
    let sut = LazyView { builder.make() }

    _ = sut.body

    #expect(builder.count == 1)
  }
}

@MainActor
private final class CountingViewBuilder {
  private(set) var count = 0

  func make() -> Text {
    count += 1
    return Text("content")
  }
}
