//
//  NotificationSettingSkeletonView.swift
//  Profile
//
//  알림 설정 로딩 스켈레톤 — 공통 SkeletonBlock(light).
//

import SwiftUI

import DesignSystem

struct NotificationSettingSkeletonView: View {
  /// 섹션별 행 개수 (기능별 2 / 소셜 3 / 마케팅 1).
  private let sectionRowCounts = [2, 3, 1]

  var body: some View {
    VStack(spacing: 20) {
      ForEach(Array(sectionRowCounts.enumerated()), id: \.offset) { _, rowCount in
        VStack(alignment: .leading, spacing: 4) {
          block(width: 90, height: 12)
            .padding(.bottom, 4)

          VStack(spacing: 0) {
            ForEach(0 ..< rowCount, id: \.self) { _ in
              HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                  block(width: 120, height: 13)
                  block(width: 180, height: 11)
                }
                Spacer(minLength: 8)
                SkeletonBlock(cornerRadius: 9, tone: .light)
                  .frame(width: 32, height: 18)
              }
              .padding(.vertical, 16)
              .overlay(alignment: .bottom) {
                Rectangle().fill(.beige600).frame(height: 1)
              }
            }
          }
        }
      }
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 16)
    .frame(maxHeight: .infinity, alignment: .top)
  }

  @ViewBuilder
  private func block(width: CGFloat, height: CGFloat) -> some View {
    SkeletonBlock(cornerRadius: 4, tone: .light)
      .frame(width: width, height: height)
  }
}
