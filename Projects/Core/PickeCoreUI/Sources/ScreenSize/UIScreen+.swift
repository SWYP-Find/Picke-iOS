//
//  UIScreen+.swift
//  PickeCoreUI
//

import SwiftUI

public extension UIScreen {
  /// 현재 화면 크기. 회전·멀티태스킹으로 값이 바뀌므로 매번 다시 읽는다.
  ///
  /// SwiftUIX 의 `Screen.main.bounds` 와 같이 접근 시점에 계산한다.
  /// (`static let` 으로 캐싱하면 앱 시작 시점의 값에 고정된다.)
  static var screenSize: CGSize { UIScreen.main.bounds.size }
  static var screenWidth: CGFloat { screenSize.width }
  static var screenHeight: CGFloat { screenSize.height }
}
