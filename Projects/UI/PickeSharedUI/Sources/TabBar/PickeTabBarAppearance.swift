//
//  PickeTabBarAppearance.swift
//  PickeSharedUI
//

import UIKit

import PickeDesignKit

/// 앱 전역 UITabBar 외형 (배경·구분선·아이템 색/폰트).
public enum PickeTabBarAppearance {
  public static func configure() {
    let selectedColor = UIColor.neutral900
    let normalColor = UIColor.gray200
    let backgroundColor = UIColor.bgDefault
    let borderColor = UIColor.borderDefault.withAlphaComponent(0.4)
    let font = UIFont.pretendardFontFamily(family: .Medium, size: 12)

    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = backgroundColor
    appearance.shadowColor = borderColor
    appearance.selectionIndicatorImage = UIImage()

    configureItemAppearance(
      appearance.stackedLayoutAppearance,
      selectedColor,
      normalColor,
      font
    )
    configureItemAppearance(
      appearance.inlineLayoutAppearance,
      selectedColor,
      normalColor,
      font
    )
    configureItemAppearance(
      appearance.compactInlineLayoutAppearance,
      selectedColor,
      normalColor,
      font
    )

    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
    UITabBar.appearance().tintColor = selectedColor
    UITabBar.appearance().unselectedItemTintColor = normalColor
  }
}

private extension PickeTabBarAppearance {
  static func configureItemAppearance(
    _ itemAppearance: UITabBarItemAppearance,
    _ selectedColor: UIColor,
    _ normalColor: UIColor,
    _ font: UIFont
  ) {
    itemAppearance.normal.iconColor = normalColor
    itemAppearance.normal.titleTextAttributes = [
      .font: font,
      .foregroundColor: normalColor,
    ]

    itemAppearance.selected.iconColor = selectedColor
    itemAppearance.selected.titleTextAttributes = [
      .font: font,
      .foregroundColor: selectedColor,
    ]
  }
}
