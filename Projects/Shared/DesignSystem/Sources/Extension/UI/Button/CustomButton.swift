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
  private var isEnable: Bool = false

  public init(
    action: @escaping () -> Void,
    title: String,
    config: PickeCustomButtonConfig,
    isEnable: Bool = false
  ) {
    self.title = title
    self.config = config
    self.action = action
    self.isEnable = isEnable
  }

  public var body: some View {
    RoundedRectangle(cornerRadius: config.cornerRadius)
      .fill(isEnable ? config.enableBackgroundColor : config.disableBackgroundColor)
      .frame(height: config.frameHeight)
      .clipShape(Capsule())
      .overlay {
        Text(title)
          .pretendardCustomFont(textStyle: .headingLarge)
          .foregroundStyle(isEnable ? config.enableFontColor : config.disableFontColor)
      }
      .onTapGesture {
        action()
      }
      .disabled(!isEnable)
  }
}
