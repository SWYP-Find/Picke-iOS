//
//  CurationSkeletonView.swift
//  Chat
//
//  Created by Picke on 10/11/26.
//

import PickeDesignKit
import SwiftUI

/// Android `RecommendListSkeleton` — 카드 4개, 좌우·위 16, 아래 80, 간격 16.
struct CurationSkeletonView: View {
  var body: some View {
    VStack(spacing: 16) {
      ForEach(0 ..< 4, id: \.self) { _ in
        card()
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 80)
    .frame(maxHeight: .infinity, alignment: .top)
    .allowsHitTesting(false)
  }

  @ViewBuilder
  private func card() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 0) {
        line(width: 50, height: 18)
        Spacer(minLength: 0)
        line(width: 70, height: 14)
      }
      line(width: 200, height: 18)
        .padding(.top, 12)
      line(width: 240, height: 14)
        .padding(.top, 6)
      HStack(spacing: 2) {
        opinionBox()
        block(.circle)
          .frame(width: 40, height: 40)
        opinionBox()
      }
      .padding(.top, 8)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .roundedBorder(
      .borderBeigeDefault,
      lineWidth: 1,
      radius: .radiusDefault,
      insideBorder: true
    )
  }

  @ViewBuilder
  private func opinionBox() -> some View {
    HStack(spacing: 4) {
      block(.circle)
        .frame(width: 40, height: 40)
      VStack(alignment: .leading, spacing: 2) {
        line(width: 50, height: 14)
        line(width: 36, height: 12)
      }
      Spacer(minLength: 0)
    }
    .padding(8)
    .frame(maxWidth: .infinity)
    .roundedBorder(
      .borderBeigeDisabled,
      lineWidth: 1,
      radius: .radiusDefault,
      insideBorder: true
    )
  }

  /// Android `PickeSkeletonLine` — radius 4, 좁은 자리에서는 줄어든다.
  private func line(
    width: CGFloat,
    height: CGFloat
  ) -> some View {
    block(.round(cornerRadius: 4))
      .frame(maxWidth: width)
      .frame(height: height)
  }

  /// Android `Modifier.shimmer()` 기본 색.
  private func block(_ shape: SkeletonShape) -> some View {
    SkeletonView(
      shape,
      base: .surfaceBeigeStrong,
      highlight: .surfaceBeigeDefault
    )
  }
}
