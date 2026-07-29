//
//  SkeletonBlock.swift
//  DesignSystem
//

import SwiftUI

public struct SkeletonBlock: View {
  /// 배경 톤 — 라이트(beige) / 다크 화면에 맞춰 base·shimmer 색을 고른다.
  public enum Tone {
    case light
    case dark

    var base: Color {
      switch self {
      case .light: Color.black.opacity(0.06)
      case .dark: Color.white.opacity(0.08)
      }
    }

    var shimmer: Color {
      switch self {
      case .light: Color.white.opacity(0.55)
      case .dark: Color.white.opacity(0.20)
      }
    }
  }

  private let cornerRadius: CGFloat
  private let tone: Tone

  @State private var phase: CGFloat = -1

  public init(
    cornerRadius: CGFloat = 4,
    tone: Tone = .light
  ) {
    self.cornerRadius = cornerRadius
    self.tone = tone
  }

  public var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(tone.base)
      .overlay {
        LinearGradient(
          stops: [
            .init(color: tone.shimmer.opacity(0), location: 0),
            .init(color: tone.shimmer, location: 0.5),
            .init(color: tone.shimmer.opacity(0), location: 1),
          ],
          startPoint: UnitPoint(x: phase, y: 0.5),
          endPoint: UnitPoint(x: phase + 1, y: 0.5)
        )
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .onAppear {
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
          phase = 2
        }
      }
  }
}
