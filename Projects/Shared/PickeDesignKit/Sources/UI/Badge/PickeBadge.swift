//
//  PickeBadge.swift
//  PickeDesignKit
//

import SwiftUI

/// 뱃지 스타일. 토큰(`ComponentToken.Badge`)과 1:1 대응한다.
public enum PickeBadgeStyle: Sendable {
  case filled
  case primary
  case outline

  var background: Color {
    switch self {
    case .filled: .badgeFilledBackground
    case .primary: .badgePrimaryBackground
    case .outline: .badgeOutlineBackground
    }
  }

  var foreground: Color {
    switch self {
    case .filled: .badgeFilledText
    case .primary: .badgePrimaryText
    case .outline: .badgeOutlineText
    }
  }

  var border: Color? {
    switch self {
    case .outline: .badgeOutlineBorder
    default: nil
    }
  }
}

/// 뱃지 크기. 코드베이스에 실제로 쓰이던 두 가지 형태를 그대로 옮겼다.
public enum PickeBadgeSize: Sendable {
  /// 카드 헤더용 — Medium 12 / px4.
  case compact
  /// 태그(#카테고리)용 — SemiBold 12 / px6.
  case tag

  var font: CustomSizeFont {
    switch self {
    case .compact: .labelSmall
    case .tag: .semiBold12
    }
  }

  var horizontalPadding: CGFloat {
    switch self {
    case .compact: 4
    case .tag: 6
    }
  }
}

public extension View {
  /// 텍스트를 뱃지로 감싼다.
  func pickeBadge(_ style: PickeBadgeStyle = .filled, size: PickeBadgeSize = .compact) -> some View {
    pretendardFont(size.font)
      .foregroundStyle(style.foreground)
      .lineLimit(1)
      .padding(.horizontal, size.horizontalPadding)
      .padding(.vertical, 2)
      .roundedBackground(style.background)
      .overlay {
        if let border = style.border {
          RoundedRectangle(cornerRadius: .radiusDefault)
            .stroke(border, lineWidth: 1)
        }
      }
  }
}
