//
//  BattlePagingBar.swift
//  Battle
//
//  빠른 배틀 상단 paging 인디케이터 — picke Figma `오늘의 배틀` Progress Bar (node 3637:3392).
//  배틀 수만큼 풀폭 세그먼트(4px)를 그리고, 현재 페이지까지 채워서(beige50) 표시.
//  세그먼트 터치 시 해당 배틀로 페이지 이동.
//

import SwiftUI

import PickeDesignKit

/// 상단 paging 바 — 세그먼트 터치로 페이지 전환. 우측에 `현재/전체` 카운트.
struct BattlePagingBar: View {
  let pageCount: Int
  let currentIndex: Int
  let onSelect: (Int) -> Void

  var body: some View {
    HStack(spacing: 4) {
      HStack(spacing: 4) {
        ForEach(0 ..< pageCount, id: \.self) { index in
          segment(index)
        }
      }

      // Figma: Pretendard Medium 12, white opacity 0.6, 우측 정렬.
      Text("\(currentIndex + 1)/\(pageCount)")
        .pretendardFont(.labelSmall)
        .foregroundStyle(.white)
        .opacity(0.6)
        .kerning(-0.264)
        .frame(width: 24, alignment: .trailing)
    }
    .padding(.horizontal, 16)
  }
}

private extension BattlePagingBar {
  /// 현재 페이지 이하 세그먼트는 beige50 으로 채우고, 이후는 gray300. 터치 시 해당 페이지로 이동.
  @ViewBuilder
  func segment(_ index: Int) -> some View {
    let isFilled = index <= currentIndex
    RoundedRectangle(cornerRadius: .radiusDefault, style: .continuous)
      .fill(isFilled ? .beige50 : .gray300)
      .frame(maxWidth: .infinity)
      .frame(height: 4)
      .animation(.easeInOut(duration: 0.2), value: currentIndex)
      .contentShape(Rectangle())
      .onTapGesture { onSelect(index) }
  }
}
