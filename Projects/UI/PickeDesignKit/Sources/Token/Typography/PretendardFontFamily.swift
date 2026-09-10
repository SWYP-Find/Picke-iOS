//
//  PretendardFontFamily.swift
//  DesignSystem
//
//  Created by 서원지 on 7/13/24.
//

import Foundation

public enum PretendardFontFamily {
  case Black
  case Bold
  case ExtraBold
  case ExtraLight
  case Light
  case Medium
  case Regular
  case SemiBold
  case Thin

  /// 번들에 든 Pretendard 를 런타임에 등록한다. 같은 파일을 여러 weight 가 공유하므로 경로로 한 번만 거른다.
  public static func registerFonts() {
    var registeredPaths = Set<String>()
    for font in PickeDesignKitFontFamily.allCustomFonts
      where registeredPaths.insert(font.path).inserted
    {
      font.register()
    }
  }
}
