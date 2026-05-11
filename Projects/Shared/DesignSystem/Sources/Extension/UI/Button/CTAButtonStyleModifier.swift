//
//  CTAButtonStyleModifier.swift
//  DesignSystem
//
//  `Button` 위에 얹는 ButtonStyle + `View.ctaButtonStyle(...)` 단축 모디파이어.
//

import SwiftUI

// MARK: - ButtonStyle

public struct CTAButtonStyle: ButtonStyle {
  private let variant: CTAButtonVariant
  private let size: CTAButtonSize
  private let trailingIcon: Image?

  public init(
    variant: CTAButtonVariant = .primary,
    size: CTAButtonSize = .large,
    trailingIcon: Image? = nil
  ) {
    self.variant = variant
    self.size = size
    self.trailingIcon = trailingIcon
  }

  public func makeBody(configuration: Configuration) -> some View {
    StyledLabel(
      configuration: configuration,
      variant: variant,
      size: size,
      trailingIcon: trailingIcon
    )
  }

  private struct StyledLabel: View {
    let configuration: Configuration
    let variant: CTAButtonVariant
    let size: CTAButtonSize
    let trailingIcon: Image?

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
      HStack(spacing: size.iconSpacing) {
        configuration.label
          .pretendardCustomFont(textStyle: size.font)
        if let trailingIcon {
          trailingIcon
        }
      }
      .foregroundStyle(variant.foregroundColor(isEnabled: isEnabled))
      .padding(.horizontal, size.horizontalPadding)
      .frame(
        maxWidth: size.fillsWidth ? .infinity : nil,
        minHeight: size.height
      )
      .background(
        variant.backgroundColor(isEnabled: isEnabled),
        in: Capsule()
      )
      .opacity(configuration.isPressed ? 0.85 : 1)
      .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
  }
}

// MARK: - View shortcut

public extension View {
  /// `Button { ... } label: { ... }` 위에 적용하는 Picke CTA 스타일.
  /// - Parameters:
  ///   - variant: 색 계열 (기본 `.primary`)
  ///   - size: `.large` / `.medium` / `.small`
  ///   - icon: 트레일링 아이콘 (옵션)
  func ctaButtonStyle(
    _ variant: CTAButtonVariant = .primary,
    size: CTAButtonSize = .large,
    icon: Image? = nil
  ) -> some View {
    buttonStyle(
      CTAButtonStyle(variant: variant, size: size, trailingIcon: icon)
    )
  }
}
