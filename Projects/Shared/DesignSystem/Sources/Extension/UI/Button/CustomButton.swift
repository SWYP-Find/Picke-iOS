//
//  CustomButton.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 11/2/24.
//

import SwiftUI

public struct CustomButton: View {
  private let action: () -> Void
  private let title: String
  private let config: PickeCustomButtonConfig
  private let trailingIcon: Image?
  private let textStyle: CustomSizeFont
  private var isEnable: Bool

  public init(
    action: @escaping () -> Void,
    title: String,
    config: PickeCustomButtonConfig,
    isEnable: Bool = false,
    trailingIcon: Image? = nil,
    textStyle: CustomSizeFont = .headingMedium
  ) {
    self.title = title
    self.config = config
    self.action = action
    self.isEnable = isEnable
    self.trailingIcon = trailingIcon
    self.textStyle = textStyle
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: .s8) {
        Text(title)
          .pretendardCustomFont(textStyle: textStyle)
        if let trailingIcon {
          trailingIcon
        }
      }
      .foregroundStyle(isEnable ? config.enableFontColor : config.disableFontColor)
      .frame(maxWidth: .infinity)
      .frame(height: config.frameHeight)
      .background(
        isEnable ? config.enableBackgroundColor : config.disableBackgroundColor,
        in: Capsule()
      )
    }
    .buttonStyle(.plain)
    .disabled(!isEnable)
  }
}
