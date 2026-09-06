//
//  PickeListRowCard.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 리스트 행 카드. 흰 배경에 하단 구분선만 두는 형태로, 카드 사이를 선으로만 나눈다.
  func pickeListRowCard(showsDivider: Bool = true) -> some View {
    padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.white)
      .overlay(alignment: .bottom) {
        if showsDivider {
          PickeDivider(.cardBaseBorderDefault)
        }
      }
  }
}
