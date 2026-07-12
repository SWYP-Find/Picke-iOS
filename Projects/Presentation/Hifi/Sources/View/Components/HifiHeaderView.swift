//
//  HifiHeaderView.swift
//  Hifi
//
//  Created by Wonji Suh  on 6/4/26.
//

import SwiftUI

import PickeDesignKit

/// 홈 화면 최상단 GNB 위 헤더 (PicKé 로고 + 알림 아이콘).
struct HifiHeaderView: View {
  let onNotificationTapped: () -> Void

  var body: some View {
    HStack {
      Image(asset: .appLogo)
        .resizable()
        .scaledToFit()
        .frame(width: 62, height: 39)

      Spacer()

      Button(action: onNotificationTapped) {
        Image(asset: .bell)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 8)
    .frame(height: 56)
    .background(.beige50)
  }
}
