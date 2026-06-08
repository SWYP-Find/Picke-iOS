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
              .stroke(.beige600, lineWidth: 1)
          )
        }
      }
      .padding(.vertical, 20)
      .padding(.horizontal, 16)
    }
  }

  @ViewBuilder
  private func block(width: CGFloat, height: CGFloat) -> some View {
    SkeletonBlock(cornerRadius: 4, tone: .light)
      .frame(width: width, height: height)
  }
}
