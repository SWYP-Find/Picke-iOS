//
//  PickeTextField.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 한 줄 입력 필드. beige50 배경 + beige600 테두리. 플레이스홀더는 `prompt:` 로 넘긴 Text 에 gray300 을 준다.
  func pickeTextField(height: CGFloat = 44) -> some View {
    pretendardFont(.labelMedium)
      .foregroundStyle(.gray800)
      .padding(.horizontal, 8)
      .frame(height: height)
      .frame(maxWidth: .infinity)
      .pickeCard(.beige50, border: .beige600)
  }
}
