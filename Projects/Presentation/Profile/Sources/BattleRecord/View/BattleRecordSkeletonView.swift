//
//  BattleRecordSkeletonView.swift
//  Profile
//
//  내 배틀 기록 로딩 스켈레톤 — 라이트(beige) shimmer.
//

import SwiftUI

import DesignSystem

struct BattleRecordSkeletonView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        ForEach(0 ..< 6, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
              block(width: 40, height: 18)
              block(width: 150, height: 16)
            }
            block(width: nil, maxWidth: true, height: 32)
            block(width: 72, height: 12)
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(.beige50, in: RoundedRectangle(cornerRadius: 8))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(.beige600, lineWidth: 1)
          )
        }
      }
      .padding(.vertical, 20)
      .padding(.horizontal, 16)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func block(
    width: CGFloat?,
    maxWidth: Bool = false,
    height: CGFloat
  ) -> some View {
    LightSkeletonBlock(cornerRadius: 4)
      .frame(width: width)
      .frame(maxWidth: maxWidth ? .infinity : nil)
      .frame(height: height)
  }
}

/// 라이트 배경용 skeleton 블록.
private struct LightSkeletonBlock: View {
  let cornerRadius: CGFloat

  @State private var phase: CGFloat = -1

  private let baseColor = Color.black.opacity(0.06)
  private let shimmerColor = Color.white.opacity(0.55)

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
