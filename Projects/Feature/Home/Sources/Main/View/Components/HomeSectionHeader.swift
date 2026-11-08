//
//  HomeSectionHeader.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import PickeDesignKit
import SwiftUI

/// "지금 뜨는 배틀" 같은 섹션 헤더 공통 컴포넌트.
struct HomeSectionHeader: View {
  let title: String

  var body: some View {
    Text(attributedTitle)
      .pretendardFont(family: .SemiBold, size: 18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      // Android headingMd 는 한 줄이라 줄높이 1.3이 잘려(Trim.Both) 글꼴 자연 높이 + 세로 12씩이다.
      .padding(.vertical, 12)
  }

  /// Figma 홈 헤더: 섹션 주제어(배틀/댓글)만 primary500으로 강조한다.
  private var attributedTitle: AttributedString {
    var attr = AttributedString(title)
    attr.foregroundColor = .textDefault
    if let range = attr.range(of: "배틀") ?? attr.range(of: "댓글") {
      attr[range].foregroundColor = .primary500
    }
    return attr
  }
}
