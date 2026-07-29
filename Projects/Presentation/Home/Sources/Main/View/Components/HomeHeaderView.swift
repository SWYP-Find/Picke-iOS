//
//  HomeHeaderView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import PickeDesignKit

/// 홈 화면 최상단 GNB 위 헤더 (PicKé 로고 + 알림 아이콘).
struct HomeHeaderView: View {
  let hasUnread: Bool
  let onNotificationTapped: () -> Void

  var body: some View {
    HStack {
      Image(asset: .appLogo)
        .resizable()
        .scaledToFit()
        .frame(width: 62, height: 39)

      Spacer()

      Button(action: onNotificationTapped) {
        bellIcon()
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 8)
    .frame(height: 56)
    .background(.beige50)
    .bottomDivider(.beige600)
  }
}

private extension HomeHeaderView {
  @ViewBuilder
  func bellIcon() -> some View {
    if hasUnread {
      Image(asset: .bell)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
    } else {
      Image(systemName: "bell")
        .font(.system(size: 20, weight: .regular))
        .foregroundStyle(.neutral900)
        .frame(width: 24, height: 24)
    }
  }
}
