//
//  FloatingErrorView.swift
//  DesignSystem
//

import SwiftUI

public struct FloatingErrorView: View {
  private let message: String

  public init(message: String) {
    self.message = message
  }

  public var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.beige50)

      Text(message)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.beige50)
        .kerning(-0.35)
        .lineSpacing(14 * 0.28)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .roundedBackground(.errorStrong, radius: 9)
    .shadow(color: Color(hex: "5B0604").opacity(0.28), radius: 5.25, x: 0, y: 0)
  }
}
