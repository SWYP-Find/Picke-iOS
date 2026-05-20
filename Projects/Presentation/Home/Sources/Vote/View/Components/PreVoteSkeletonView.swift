//
//  PreVoteSkeletonView.swift
//  Home
//
//  PreVoteView 의 로딩 상태 placeholder.
//

import SwiftUI

import DesignSystem

struct PreVoteSkeletonView: View {
  private static let designWidth: CGFloat = 375
  private static let designHeight: CGFloat = 812
  private static let ctaHeight: CGFloat = 52
  private static let ctaBottomSpacing: CGFloat = 40

  var body: some View {
    GeometryReader { proxy in
      let scale = proxy.size.width / Self.designWidth

      ZStack(alignment: .topLeading) {
        Color.beige50

        // 상단 이미지 영역: PreVoteView backgroundImage 높이와 동일.
        block(width: 375, height: 512, x: 0, y: 0, cornerRadius: 0)

        // Navigation bar
        block(width: 20, height: 10, x: 20, y: 56, cornerRadius: 2)
        block(width: 24, height: 24, x: 331, y: 50, cornerRadius: 2)

        // 태그 2개
        block(width: 29, height: 17, x: 20, y: 370)
        block(width: 49, height: 17, x: 58, y: 370)

        // 타이틀
        block(width: 210, height: 68, x: 20, y: 407)

        // 설명
        block(width: 265, height: 61, x: 20, y: 487)

        // 좌/우 옵션 카드
        block(width: 163.5, height: 104, x: 20, y: 580)
        block(width: 163.5, height: 104, x: 191.5, y: 580)

        // VS badge
        block(width: 28, height: 28, x: 173.5, y: 632, cornerRadius: 14)

        // CTA: picke.pen Button/Primary/Large 343x52, 하단 40.
        block(
          width: 343,
          height: Self.ctaHeight,
          x: 20,
          y: Self.designHeight - Self.ctaBottomSpacing - Self.ctaHeight
        )
      }
      .frame(width: Self.designWidth, height: Self.designHeight, alignment: .topLeading)
      .scaleEffect(scale, anchor: .topLeading)
      .frame(
        width: proxy.size.width,
        height: Self.designHeight * scale,
        alignment: .topLeading
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  @ViewBuilder
  private func block(
    width: CGFloat,
    height: CGFloat,
    x: CGFloat,
    y: CGFloat,
    cornerRadius: CGFloat = 6
  ) -> some View {
    SkeletonView(cornerRadius: cornerRadius)
      .frame(width: width, height: height)
      .offset(x: x, y: y)
  }
}
