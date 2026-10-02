//
//  PickeChoiceChip.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 그리드 단일 선택 칩. 선택 시 primary50 채움 + primary500 테두리, 미선택 시 beige 카드.
  func pickeChoiceChip(isSelected: Bool) -> some View {
    pretendardFont(isSelected ? .headingSmall : .bodyMedium)
      .foregroundStyle(isSelected ? .primary500 : .gray300)
      .lineLimit(1)
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .contentShape(Rectangle())
      .pickeCard(
        isSelected ? .primary50 : .beige50,
        border: isSelected ? .primary500 : .beige600
      )
  }
}
