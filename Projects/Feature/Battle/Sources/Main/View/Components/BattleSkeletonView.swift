//
//  BattleSkeletonView.swift
//  Battle
//

import SwiftUI

import PickeDesignKit

struct BattleSkeletonView: View {
  var body: some View {
    VStack(spacing: 32) {
      VStack(spacing: 16) {
        block(width: 120, height: 18)
        block(width: 260, height: 28)
        block(width: 220, height: 18)
        block(width: 90, height: 28)
      }

      VStack(spacing: 12) {
        block(maxWidth: true, height: 96)
        block(maxWidth: true, height: 96)
      }

      block(maxWidth: true, height: 52)
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }

  @ViewBuilder
  private func block(
    width: CGFloat? = nil,
    maxWidth: Bool = false,
    height: CGFloat
  ) -> some View {
    DarkSkeletonBlock(cornerRadius: .radiusDefault)
      .frame(width: width)
      .frame(maxWidth: maxWidth ? .infinity : nil)
      .frame(height: height)
  }
}

/// 다크 배경용 skeleton 블록 (어두운 base + 옅은 흰색 shimmer).
private struct DarkSkeletonBlock: View {
  private static let baseColor = Color.white.opacity(0.08)
  private static let shimmerColor = Color.white.opacity(0.20)

  let cornerRadius: CGFloat

  var body: some View {
    SkeletonView(
      .round(cornerRadius: cornerRadius),
      base: Self.baseColor,
      highlight: Self.shimmerColor
    )
  }
}
