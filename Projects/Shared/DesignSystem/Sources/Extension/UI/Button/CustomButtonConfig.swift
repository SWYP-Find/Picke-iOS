//
//  CustomButtonConfig.swift
//  DesignSystem
//
//  Created by Wonji Suh  on 11/2/24.
//

import SwiftUI

public class CustomButtonConfig: PickeCustomButtonConfig {
  public static func create() -> PickeCustomButtonConfig {
    let config = PickeCustomButtonConfig(
      cornerRadius: .full,
      enableFontColor: .bgDefault,
      enableBackgroundColor: .primary500,
      frameHeight: 60,
      disableFontColor: .neutral500,
      disableBackgroundColor: .neutral100
    )

    return config
  }
}
