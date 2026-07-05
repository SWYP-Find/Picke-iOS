//
//  View+Background.swift
//  DesignSystem
//
//  반복되는 라운드 배경 관용구를 체이닝 모디파이어로 추출.
//

import SwiftUI

public extension View {
  /// `.background(color, in: RoundedRectangle(cornerRadius: radius))` 축약.
  func roundedBackground(_ color: Color, radius: CGFloat = .radiusDefault) -> some View {
    background(color, in: RoundedRectangle(cornerRadius: radius))
  }
}
