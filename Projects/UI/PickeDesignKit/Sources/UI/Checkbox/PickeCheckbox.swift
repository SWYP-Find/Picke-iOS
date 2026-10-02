//
//  PickeCheckbox.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 원형 체크박스. 체크 아이콘 뷰에 붙이면 선택 시에만 아이콘이 보인다.
  func pickeCheckbox(
    isChecked: Bool,
    size: CGFloat = 20
  ) -> some View {
    pretendardFont(.bold10)
      .foregroundStyle(.beige50)
      .opacity(isChecked ? 1 : 0)
      .frame(width: size, height: size)
      .background {
        Circle()
          .fill(isChecked ? ComponentToken.Checkbox.Background.selected : ComponentToken.Checkbox.Background.default)
      }
      .overlay {
        Circle()
          .stroke(
            isChecked ? ComponentToken.Checkbox.Border.selected : ComponentToken.Checkbox.Border.default,
            lineWidth: 1
          )
      }
  }
}
