//
//  SkeletonView.swift
//  DesignSystem
//
//  KFImage 등 비동기 이미지 로딩 placeholder 용 공용 skeleton.
//  shimmer 그라데이션을 좌→우로 반복해 로딩 중임을 시각화한다.
//

import SwiftUI

public struct SkeletonView: View {
  private let cornerRadius: CGFloat
  private let baseColor: Color
  private let shimmerColor: Color

  public init(
    cornerRadius: CGFloat = 2,
    baseColor: Color = .beige600,
    shimmerColor: Color = .beige50
  ) {
    self.cornerRadius = cornerRadius
    self.baseColor = baseColor
    self.shimmerColor = shimmerColor
  }

  @State private var phase: CGFloat = -1

  public var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(baseColor)
      .overlay {
        LinearGradient(
          stops: [
            .init(color: baseColor.opacity(0), location: 0),
            .init(color: shimmerColor.opacity(0.6), location: 0.5),
            .init(color: baseColor.opacity(0), location: 1),
          ],
          startPoint: UnitPoint(x: phase, y: 0.5),
          endPoint: UnitPoint(x: phase + 1, y: 0.5)
        )
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .onAppear {
        withAnimation(
          .linear(duration: 1.2).repeatForever(autoreverses: false)
        ) {
          phase = 2
        }
      }
  }
}
