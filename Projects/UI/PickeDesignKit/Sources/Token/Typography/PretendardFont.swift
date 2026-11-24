//
//  PretendardFont.swift
//  PickeDesignKit
//
//  Created by Picke on 6/9/24.
//

import SwiftUI

public struct PretendardFont: ViewModifier {
  public let family: PretendardFontFamily
  public let size: CGFloat

  public func body(content: Content) -> some View {
    content
      .font(
        .custom(
          "PretendardVariable-\(family)",
          fixedSize: size
        )
      )
  }
}

public extension View {
  func pretendardFont(
    family: PretendardFontFamily,
    size: CGFloat
  ) -> some View {
    modifier(
      PretendardFont(
        family: family,
        size: size
      )
    )
  }

  func pretendardFont(_ textStyle: CustomSizeFont) -> some View {
    modifier(
      PretendardFont(
        family: textStyle.fontFamily,
        size: textStyle.size
      )
    )
  }

  /// Figma 줄 높이에 맞춘다. `lineHeightMultiple`은 글자 크기 대비 배수(1.4 = 140%)이고 절대값이 아니다.
  /// 줄 사이와 첫 줄 위·마지막 줄 아래에 남는 높이를 나눠 더하므로 배지처럼 배경 높이를 따로 정한 텍스트,
  /// 높이가 고정된 컨테이너 안 여러 줄 텍스트에는 쓰지 않는다.
  func pretendardFont(
    _ textStyle: CustomSizeFont,
    lineHeightMultiple: CGFloat
  ) -> some View {
    let naturalLineHeight = UIFont.pretendardFontFamily(
      family: textStyle.fontFamily,
      size: textStyle.size
    ).lineHeight
    let extra = max(0, textStyle.size * lineHeightMultiple - naturalLineHeight)
    return pretendardFont(textStyle)
      .lineSpacing(extra)
      .padding(.vertical, extra / 2)
  }

  /// Android Compose 기본 줄높이(`LineHeightStyle.Default` = Trim.Both)와 같게 줄 사이만 벌린다.
  /// 첫 줄 위·마지막 줄 아래는 늘리지 않으므로 한 줄이면 글꼴 자연 높이, n줄이면 자연 높이 + (n−1) × 글자 크기 × 배수다.
  func pretendardFont(
    _ textStyle: CustomSizeFont,
    lineSpacingMultiple: CGFloat
  ) -> some View {
    let naturalLineHeight = UIFont.pretendardFontFamily(
      family: textStyle.fontFamily,
      size: textStyle.size
    ).lineHeight
    return pretendardFont(textStyle)
      .lineSpacing(max(0, textStyle.size * lineSpacingMultiple - naturalLineHeight))
  }
}

public extension UIFont {
  static func pretendardFontFamily(
    family: PretendardFontFamily,
    size: CGFloat
  ) -> UIFont {
    let fontName = "PretendardVariable-\(family)"
    return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size, weight: .regular)
  }
}

public extension Font {
  static func pretendardFontFamily(
    family: PretendardFontFamily,
    size: CGFloat
  ) -> Font {
    let font = Font.custom("PretendardVariable-\(family)", size: size)
    return font
  }

  /// Dynamic Type 에 커지지 않는 고정 크기 — `pretendardFont(_:)` 와 같은 `fixedSize`.
  static func pretendardFontFamily(
    family: PretendardFontFamily,
    fixedSize: CGFloat
  ) -> Font {
    return Font.custom("PretendardVariable-\(family)", fixedSize: fixedSize)
  }
}
