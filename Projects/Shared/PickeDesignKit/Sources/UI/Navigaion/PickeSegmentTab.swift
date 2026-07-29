//
//  PickeSegmentTab.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 상단 세그먼트 탭 한 칸. 선택 시 primary 밑줄 2.5, 미선택 시 gray 베이스라인 1.
  func pickeSegmentTab(isSelected: Bool) -> some View {
    pretendardFont(.labelMedium)
      .foregroundStyle(isSelected ? .navigationTabTextActive : .navigationTabTextDefault)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) {
        Rectangle()
          .fill(isSelected ? .navigationTabBorderActive : .navigationTabBorderDefault)
          .frame(height: isSelected ? 2.5 : 1)
      }
  }
}
