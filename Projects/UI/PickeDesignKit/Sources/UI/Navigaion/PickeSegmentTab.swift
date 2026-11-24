//
//  PickeSegmentTab.swift
//  PickeDesignKit
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

public extension View {
  /// 상단 세그먼트 탭 한 칸 — Android `PickeTabBar`(TabRow).
  /// 글자 14(선택 Bold `primary500`, 미선택 Regular `textMuted`), 안쪽 가로 4·세로 16,
  /// 아래 2 구분선(`borderBeigeDefault`) 위에 선택 탭만 2 `primary500` 밑줄. 칸은 가로를 등분한다.
  func pickeSegmentTab(isSelected: Bool) -> some View {
    pretendardFont(
      family: isSelected ? .Bold : .Regular,
      size: 14
    )
    .foregroundStyle(isSelected ? .primary500 : .textMuted)
    .lineLimit(1)
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 4)
    .padding(.vertical, 16)
    .contentShape(Rectangle())
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(isSelected ? .primary500 : .borderBeigeDefault)
        .frame(height: 2)
    }
  }
}
