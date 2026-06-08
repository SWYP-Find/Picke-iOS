//
//  PointHistorySkeletonView.swift
//  Profile
//
//  포인트 내역 로딩 스켈레톤 — 라이트(beige) 배경 shimmer.
//

import SwiftUI

import DesignSystem

struct PointHistorySkeletonView: View {
  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 16) {
        ForEach(0 ..< 8, id: \.self) { _ in
          HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
              block(width: 80, height: 14)
              block(width: 64, height: 12)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
              block(width: 48, height: 14)
              block(width: 28, height: 12)
            }
          }
          .padding(16)
          .frame(maxWidth: .infinity)
          .background(Color.beige50)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.beige600, lineWidth: 1)
          )
        }
      }
      .padding(.vertical, 20)
      .padding(.horizontal, 16)
    }
  }

  @ViewBuilder
  private func block(width: CGFloat, height: CGFloat) -> some View {
    LightSkeletonBlock(cornerRadius: 4)
      .frame(width: width, height: height)
  }
}

/// 라이트 배경용 skeleton 블록 (옅은 회색 base + 흰색 shimmer).
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
