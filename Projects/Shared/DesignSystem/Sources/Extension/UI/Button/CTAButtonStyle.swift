//
//  CTAButtonStyle.swift
//  DesignSystem
//
//  Picke CTA 버튼 디자인 토큰 (variant × size).
//

import SwiftUI

// MARK: - Variant

public enum CTAButtonVariant: Sendable {
  /// `primary500` 배경 + `bgDefault` 텍스트. 비활성 시 `surfaceDisabled`(primary200).
  case primary
}

public extension CTAButtonVariant {
  func backgroundColor(isEnabled: Bool) -> Color {
    switch self {
    case .primary: isEnabled ? .primary500 : .surfaceDisabled
    }
  }

  func foregroundColor(isEnabled _: Bool) -> Color {
    switch self {
    case .primary: .bgDefault
    }
  }
}

// MARK: - Size

public enum CTAButtonSize: Sendable {
  /// 풀 너비 CTA. 메인 액션용.
  case large
  /// 고정 너비 CTA. 보조 영역용.
  case medium
  /// 칩 형태 인라인 액션.
  case small
}

public extension CTAButtonSize {
  var height: CGFloat {
    switch self {
    case .large: 56
    case .medium: 48
    case .small: 36
    }
  }

  var horizontalPadding: CGFloat {
    switch self {
    case .large: .s24
    case .medium: .s16
    case .small: .s16
    }
  }

  var iconSpacing: CGFloat {
    switch self {
    case .large, .medium: .s8
    case .small: .s4
    }
  }

  var font: CustomSizeFont {
    switch self {
    case .large, .medium: .headingMedium
    case .small: .labelSmall
    }
  }

  /// 부모 컨테이너의 가로 폭을 모두 채우는지.
  var fillsWidth: Bool {
    switch self {
    case .large: true
    case .medium, .small: false
    }
  }
}
