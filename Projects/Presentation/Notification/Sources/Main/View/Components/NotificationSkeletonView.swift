//
//  NotificationSkeletonView.swift
//  Notification
//
//  알림받기 로딩 스켈레톤 — 공통 SkeletonBlock(light).
//

import SwiftUI

import DesignSystem

struct NotificationSkeletonView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        ForEach(0 ..< 7, id: \.self) { _ in
          HStack(alignment: .center, spacing: 16) {
            SkeletonBlock(cornerRadius: 12, tone: .light)
              .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {
              HStack {
                block(width: 120, height: 12)
                Spacer(minLength: 0)
                block(width: 40, height: 12)
              }
              block(width: nil, maxWidth: true, height: 16)
            }
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(.beige50, in: RoundedRectangle(cornerRadius: .radiusDefault))
          .overlay(
            RoundedRectangle(cornerRadius: .radiusDefault)
              .stroke(.beige600, lineWidth: 1)
          )
        }
      }
      .padding(.top, 8)
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
