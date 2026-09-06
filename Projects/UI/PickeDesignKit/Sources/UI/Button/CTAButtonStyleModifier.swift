//
//  CTAButtonStyleModifier.swift
//  DesignSystem
//

import SwiftUI

// MARK: - ButtonStyle

public struct CTAButtonStyle: ButtonStyle {
  private let variant: CTAButtonVariant
  private let size: CTAButtonSize
  private let height: CGFloat?
  private let cornerRadius: CGFloat
  private let trailingIcon: Image?

  public init(
    variant: CTAButtonVariant = .primary,
    size: CTAButtonSize = .large,
    height: CGFloat? = nil,
    cornerRadius: CGFloat = .radiusDefault,
    trailingIcon: Image? = nil
  ) {
    self.variant = variant
    self.size = size
    self.height = height
    self.cornerRadius = cornerRadius
    self.trailingIcon = trailingIcon
  }

  public func makeBody(configuration: Configuration) -> some View {
    StyledLabel(
      configuration: configuration,
      variant: variant,
      size: size,
      height: height,
      cornerRadius: cornerRadius,
      trailingIcon: trailingIcon
    )
  }

  private struct StyledLabel: View {
    let configuration: Configuration
    let variant: CTAButtonVariant
    let size: CTAButtonSize
    let height: CGFloat?
    let cornerRadius: CGFloat
    let trailingIcon: Image?

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
      HStack(spacing: size.iconSpacing) {
        configuration.label
          .pretendardFont(size.font)
        if let trailingIcon {
          trailingIcon
        }
      }
      .foregroundStyle(variant.foregroundColor(isEnabled: isEnabled))
      .padding(.horizontal, size.horizontalPadding)
      .frame(maxWidth: size.fillsWidth ? .infinity : nil)
      .frame(height: height ?? size.height)
      .background(
        variant.backgroundColor(isEnabled: isEnabled, isPressed: configuration.isPressed),
        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
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
    height: CGFloat? = nil,
    cornerRadius: CGFloat = .radiusDefault,
    icon: Image? = nil
  ) -> some View {
    buttonStyle(
      CTAButtonStyle(
        variant: variant,
        size: size,
        height: height,
        cornerRadius: cornerRadius,
        trailingIcon: icon
      )
    )
  }
}
