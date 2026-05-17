//
//  CustomButtonConfig.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 11/2/24.
//

import SwiftUI

public class CustomButtonConfig: PickeCustomButtonConfig {
  /// 기본 large primary CTA. 기존 호출처 호환을 위해 유지.
  public static func create() -> PickeCustomButtonConfig {
    primary(.large)
  }

  /// CTA primary 팩토리. variant + size 조합을 `PickeCustomButtonConfig`로 변환한다.
  /// - Parameters:
  ///   - size: `CTAButtonSize` (기본 height 사용)
  ///   - height: 호출처에서 size.height 를 override 하고 싶을 때 명시 (e.g. .pen 디자인의 52pt)
  public static func primary(
    _ size: CTAButtonSize,
    height: CGFloat? = nil
  ) -> PickeCustomButtonConfig {
    let variant: CTAButtonVariant = .primary
    return PickeCustomButtonConfig(
      cornerRadius: .default,
      enableFontColor: variant.foregroundColor(isEnabled: true),
      enableBackgroundColor: variant.backgroundColor(isEnabled: true),
      frameHeight: height ?? size.height,
      disableFontColor: variant.foregroundColor(isEnabled: false),
      disableBackgroundColor: variant.backgroundColor(isEnabled: false)
    )
  }
}
