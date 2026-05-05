//
//  CustomSize.swift
//  DesignSystem
//
//  Picke Figma typography tokens (name / size / weight).
//

import Foundation

public enum CustomSizeFont {
  case headingXXLarge
  case headingXLarge
  case headingLarge
  case headingMedium
  case headingSmall

  case bodyLarge
  case bodyMedium
  case bodySmall

  case labelLarge
  case labelMedium
  case labelSmall
  case labelXSmall

  public var size: CGFloat {
    switch self {
    case .headingXXLarge: 30
    case .headingXLarge: 30
    case .headingLarge: 20
    case .headingMedium: 16
    case .headingSmall: 14
    case .bodyLarge: 16
    case .bodyMedium: 14
    case .bodySmall: 12
    case .labelLarge: 16
    case .labelMedium: 14
    case .labelSmall: 12
    case .labelXSmall: 10
    }
  }

  public var fontFamily: PretendardFontFamily {
    switch self {
    case .headingXXLarge,
         .headingXLarge,
         .headingLarge,
         .headingMedium,
         .headingSmall,
         .labelXSmall:
      .SemiBold
    case .bodyLarge,
         .bodyMedium,
         .bodySmall:
      .Regular
    case .labelLarge:
      .Bold
    case .labelMedium,
         .labelSmall:
      .Medium
    }
  }
}
