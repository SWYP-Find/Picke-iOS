//
//  PickePill.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 캡슐형 조건 뱃지. primary50 채움 + primary500 텍스트.
  func pickePill() -> some View {
    pretendardFont(.semiBold12)
      .foregroundStyle(.primary500)
      .lineLimit(1)
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .background(.primary50, in: Capsule())
  }
}
