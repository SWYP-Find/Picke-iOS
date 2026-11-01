//
//  HomeSectionHeader.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import SwiftUI

import PickeDesignKit

/// "지금 뜨는 배틀 / 더 보기" 같은 섹션 헤더 공통 컴포넌트.
struct HomeSectionHeader: View {
  let title: String
  let onSeeMoreTapped: (() -> Void)?

  var body: some View {
    HStack(spacing: 12) {
      Text(attributedTitle)
        .pretendardFont(.bold18)
        .kerning(-0.45)
      Spacer(minLength: 0)
      if let onSeeMoreTapped {
        Button(action: onSeeMoreTapped) {
          Text("더 보기")
            .pretendardFont(.medium13)
            .foregroundStyle(.neutral300)
        }
      }
    }
    .padding(.horizontal, 16)
  }

  /// Figma 홈 헤더: 섹션 주제어(배틀/댓글)만 primary500으로 강조한다.
  private var attributedTitle: AttributedString {
    var attr = AttributedString(title)
    attr.foregroundColor = .neutral900
    if let range = attr.range(of: "배틀") ?? attr.range(of: "댓글") {
      attr[range].foregroundColor = .primary500
    }
    return attr
  }
}
