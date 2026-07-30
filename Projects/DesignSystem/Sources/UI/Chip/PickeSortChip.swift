//
//  PickeSortChip.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 정렬/필터용 칩. 선택 시 primary 채움, 미선택 시 primary 라인.
  func pickeSortChip(isSelected: Bool) -> some View {
    pretendardFont(.medium13)
      .foregroundStyle(isSelected ? .chipTextDefault : .chipTextSelected)
      .lineLimit(1)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .roundedBackground(isSelected ? .chipBackgroundDefault : .chipBackgroundSelected)
      .overlay {
        if !isSelected {
          RoundedRectangle(cornerRadius: .radiusDefault)
            .stroke(.chipBorderDefault, lineWidth: 1)
        }
      }
  }
}
