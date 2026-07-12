//
//  BattleRecordSkeletonView.swift
//  Profile
//
//  내 배틀 기록 로딩 스켈레톤 — 공통 SkeletonBlock(light) 사용.
//

import SwiftUI

import PickeDesignKit

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
          .roundedBackground(.beige50, radius: 8)
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
    SkeletonBlock(cornerRadius: 4, tone: .light)
      .frame(width: width)
      .frame(maxWidth: maxWidth ? .infinity : nil)
      .frame(height: height)
  }
}
