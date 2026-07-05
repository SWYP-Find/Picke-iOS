//
//  BattleSkeletonView.swift
//  Battle
//
//  오늘의 배틀 로딩 스켈레톤 — 다크 배경에 맞춘 어두운 shimmer.
//

import SwiftUI

import DesignSystem

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
  let cornerRadius: CGFloat

  @State private var phase: CGFloat = -1

  private let baseColor = Color.white.opacity(0.08)
  private let shimmerColor = Color.white.opacity(0.20)

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(baseColor)
      .overlay {
        LinearGradient(
          stops: [
            .init(color: shimmerColor.opacity(0), location: 0),
            .init(color: shimmerColor, location: 0.5),
            .init(color: shimmerColor.opacity(0), location: 1),
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
