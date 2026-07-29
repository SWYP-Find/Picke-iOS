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
}
