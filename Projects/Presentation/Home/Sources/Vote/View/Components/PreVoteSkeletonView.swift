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

  var body: some View {
    GeometryReader { proxy in
      let scale = proxy.size.width / Self.designWidth

      ZStack(alignment: .topLeading) {
        Color.beige50

        block(width: 375, height: 329.25, x: 0, y: 0)
        block(width: 375, height: 60, x: 0, y: 70)

        block(width: 29, height: 17, x: 22, y: 360)
        block(width: 49, height: 17, x: 72, y: 360)

        block(width: 167, height: 68, x: 16, y: 399)
        block(width: 235.51, height: 61.43, x: 16, y: 479)

        block(width: 167, height: 105.72, x: 14.63, y: 574.04)
        block(width: 167, height: 105.72, x: 193.38, y: 574.04)
        block(width: 15, height: 15, x: 373.5, y: 619)

        block(width: 87, height: 24, x: 144, y: 734)
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
