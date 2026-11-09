//
//  PickeMoreMenuView.swift
//  PickeSharedUI
//
//  Created by Picke on 11/10/26.
//

import PickeDesignKit
import SwiftUI

/// Android `PickeMoreMenu` 의 펼친 목록 — 알약(radius 24, 최소 70×34, 가로 6, primary500),
/// 아이콘 + 13 Medium 글자(iconGrayInverse) 간격 4, 항목 간격 4.
public struct PickeMoreMenuView: View {
  private let items: [PickeMoreMenuItem]

  public init(items: [PickeMoreMenuItem]) {
    self.items = items
  }

  public var body: some View {
    VStack(alignment: .trailing, spacing: 4) {
      ForEach(items) { item in
        Button(action: item.action) {
          HStack(spacing: 4) {
            Image(asset: item.icon)
              .renderingMode(.template)
            Text(item.title)
              .pretendardFont(.medium13)
          }
          .foregroundStyle(.iconGrayInverse)
          .padding(.horizontal, 6)
          .frame(minWidth: 70, minHeight: 34)
          .background(.buttonIconBackgroundDefault, in: RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
      }
    }
  }
}
