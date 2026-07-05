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
      Text(attributedTitle)
        .pretendardFont(.bold18)
        .kerning(-0.45)
      Spacer(minLength: 0)
      Button(action: onSeeMoreTapped) {
        Text("더 보기")
          .pretendardFont(.medium13)
          .foregroundStyle(.neutral300)
      }
    }
    .padding(.horizontal, 16)
  }

  /// 강조 규칙:
  /// - 라틴 단어 (Best · Pické 등) 가 있으면 그 단어만 primary500, 나머지 한글은 neutral900
  /// - 라틴 단어가 없으면 한글 `배틀` 만 primary500, 나머지 한글은 neutral900
  private var attributedTitle: AttributedString {
    var attr = AttributedString(title)
    attr.foregroundColor = .neutral900

    let latinPattern = /[A-Za-zÀ-ÿ]+/
    let latinMatches = Array(title.matches(of: latinPattern))

    if latinMatches.isEmpty {
      if let range = attr.range(of: "배틀") {
        attr[range].foregroundColor = .primary500
      }
    } else {
      for match in latinMatches {
        if let range = attr.range(of: String(match.0)) {
          attr[range].foregroundColor = .primary500
        }
      }
    }
    return attr
  }
}
