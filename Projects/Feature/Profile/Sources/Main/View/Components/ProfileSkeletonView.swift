//
//  ProfileSkeletonView.swift
//  Profile
//

import SwiftUI

import PickeDesignKit

struct ProfileSkeletonView: View {
  var body: some View {
    VStack(spacing: 20) {
      // 프로필 카드 자리
      HStack(spacing: 12) {
        block(width: 52, height: 52, radius: 26)
        VStack(alignment: .leading, spacing: 8) {
          block(width: 140, height: 16)
          block(width: 80, height: 13)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 16)

      VStack(spacing: 16) {
        block(maxWidth: true, height: 64, radius: 8) // 포인트 충전 버튼
        block(maxWidth: true, height: 72, radius: 8) // 나의 철학자 유형
      }
      .padding(.horizontal, 16)

      // 메뉴 리스트 자리
      VStack(spacing: 0) {
        ForEach(0 ..< 3, id: \.self) { _ in
          HStack {
            block(width: 100, height: 16)
            Spacer()
          }
          .padding(.vertical, 20)
          .bottomDivider(.beige600)
        }
      }
      .padding(.horizontal, 16)

      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  private func block(
    width: CGFloat? = nil,
    maxWidth: Bool = false,
    height: CGFloat,
    radius: CGFloat = 4
  ) -> some View {
    SkeletonView(.round(cornerRadius: radius))
      .frame(width: width)
      .frame(maxWidth: maxWidth ? .infinity : nil)
      .frame(height: height)
  }
}
