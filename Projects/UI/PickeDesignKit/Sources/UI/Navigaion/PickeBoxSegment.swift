//
//  PickeBoxSegment.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 박스형 세그먼트의 한 칸. 선택 시 beige50 박스 + primary500 텍스트.
  func pickeBoxSegment(isSelected: Bool) -> some View {
    pretendardFont(isSelected ? .headingSmall : .bodyMedium)
      .foregroundStyle(isSelected ? .primary500 : .gray300)
      .frame(maxWidth: .infinity)
      .frame(height: 36)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: .radiusDefault)
            .fill(.beige50)
        }
      }
      .contentShape(Rectangle())
  }

  /// 박스형 세그먼트 칸들을 감싸는 gray50 트랙.
  func pickeBoxSegmentTrack() -> some View {
    padding(4)
      .roundedBackground(.gray50)
  }
}
