//
//  ScreenSizeTests.swift
//  PickeCoreUITests
//

import UIKit
import Testing

@testable import PickeCoreUI

@MainActor
struct ScreenSizeTests {
  /// `static let` 으로 캐싱하면 앱 시작 시점 값에 고정되므로, 접근할 때마다 다시 읽어야 한다.
  @Test
  func 화면_크기는_접근_시점의_bounds_를_반영한다() {
    #expect(UIScreen.screenSize == UIScreen.main.bounds.size)
    #expect(UIScreen.screenWidth == UIScreen.main.bounds.width)
    #expect(UIScreen.screenHeight == UIScreen.main.bounds.height)
  }
}
