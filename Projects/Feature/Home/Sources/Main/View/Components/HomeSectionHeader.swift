//
//  HomeSectionHeader.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import PickeDesignKit
import SwiftUI
import UIKit

/// "지금 뜨는 배틀" 같은 섹션 헤더 공통 컴포넌트.
struct HomeSectionHeader: View {
  let title: String

  var body: some View {
    Text(attributedTitle)
      .pretendardFont(family: .SemiBold, size: 18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, Self.verticalPadding)
  }

  /// Android headingMd(18 SemiBold, 줄높이 1.3) 대비 모자란 줄높이를 세로 패딩(기본 12)에 나눠 더한다.
  private static let verticalPadding: CGFloat = {
    let naturalLineHeight = UIFont.pretendardFontFamily(family: .SemiBold, size: 18).lineHeight
    return 12 + max(0, 18 * 1.3 - naturalLineHeight) / 2
  }()

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
