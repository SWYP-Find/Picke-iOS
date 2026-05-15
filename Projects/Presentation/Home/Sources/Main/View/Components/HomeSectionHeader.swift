//
//  HomeSectionHeader.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem

/// "지금 뜨는 배틀 / 더 보기" 같은 섹션 헤더 공통 컴포넌트.
struct HomeSectionHeader: View {
  let title: String
  let onSeeMoreTapped: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text(title)
        .pretendardFont(family: .Bold, size: 18)
        .kerning(-0.45)
        .foregroundStyle(.neutral900)
      Spacer(minLength: 0)
      Button(action: onSeeMoreTapped) {
        Text("더 보기")
          .pretendardFont(family: .Medium, size: 13)
          .foregroundStyle(.neutral300)
      }
    }
    .padding(.horizontal, 16)
  }
}
