//
//  ContentActivitySkeletonView.swift
//  Profile
//
//  내 콘텐츠 활동 로딩 스켈레톤 — 공통 SkeletonBlock(light).
//

import SwiftUI

import PickeDesignKit

struct ContentActivitySkeletonView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        ForEach(0 ..< 5, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
              SkeletonBlock(cornerRadius: 18, tone: .light)
                .frame(width: 36, height: 36)
              VStack(alignment: .leading, spacing: 4) {
                block(width: 120, height: 14)
                block(width: 50, height: 10)
              }
              Spacer(minLength: 0)
            }
            block(width: nil, maxWidth: true, height: 36)
            HStack {
              Spacer()
              block(width: 40, height: 12)
            }
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
