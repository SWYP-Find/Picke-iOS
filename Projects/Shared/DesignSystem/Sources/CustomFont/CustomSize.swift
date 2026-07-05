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

  // MARK: - Weight × Size grid (시맨틱 토큰 밖 사이즈용, ios-app 정렬)

  case regular10
  case regular11
  case regular13

  case medium10
  case medium11
  case medium13
  case medium15

  case semiBold11
  case semiBold12
  case semiBold13
  case semiBold15
  case semiBold24

  case bold8
  case bold10
  case bold11
  case bold13
  case bold18
  case bold24
  case bold28

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
    case .bold8: 8
    case .regular10, .medium10, .bold10: 10
    case .regular11, .medium11, .semiBold11, .bold11: 11
    case .semiBold12: 12
    case .regular13, .medium13, .semiBold13, .bold13: 13
    case .medium15, .semiBold15: 15
    case .bold18: 18
    case .semiBold24, .bold24: 24
    case .bold28: 28
    }
  }

  public var fontFamily: PretendardFontFamily {
    switch self {
    case .headingXXLarge,
         .headingXLarge,
         .headingLarge,
         .headingMedium,
         .headingSmall,
         .labelXSmall,
         .semiBold11,
         .semiBold12,
         .semiBold13,
         .semiBold15,
         .semiBold24:
      .SemiBold
    case .bodyLarge,
         .bodyMedium,
         .bodySmall,
         .regular10,
         .regular11,
         .regular13:
      .Regular
    case .labelLarge,
         .bold8,
         .bold10,
         .bold11,
         .bold13,
         .bold18,
         .bold24,
         .bold28:
      .Bold
    case .labelMedium,
         .labelSmall,
         .medium10,
         .medium11,
         .medium13,
         .medium15:
      .Medium
    }
  }
}
