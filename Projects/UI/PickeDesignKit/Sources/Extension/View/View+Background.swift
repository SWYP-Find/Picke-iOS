//
//  View+Background.swift
//  DesignSystem
//

import SwiftUI

public extension View {
  /// `.background(color, in: RoundedRectangle(cornerRadius: radius))` 축약.
  func roundedBackground(_ color: Color, radius: CGFloat = .radiusDefault) -> some View {
    background(color, in: RoundedRectangle(cornerRadius: radius))
  }

  /// 화면 전체 배경 — 세이프에어리어까지 채운다.
  func screenBackground(_ color: Color = .beige200) -> some View {
    background(color.ignoresSafeArea())
  }

  /// 시스템 내비게이션 바 + 탭 바를 함께 숨긴다.
  func hidesSystemBars() -> some View {
    toolbar(.hidden, for: .navigationBar)
      .toolbar(.hidden, for: .tabBar)
  }
}
