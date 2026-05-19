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

  public init(cornerRadius: CGFloat = 2) {
    self.cornerRadius = cornerRadius
  }

  @State private var phase: CGFloat = -1

  private let baseColor = Color(red: 239 / 255, green: 234 / 255, blue: 224 / 255) // beige600 #EFEAE0
  private let shimmerColor = Color(red: 254 / 255, green: 254 / 255, blue: 253 / 255) // beige50 #FEFEFD

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
