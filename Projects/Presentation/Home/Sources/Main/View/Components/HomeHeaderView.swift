//
//  HomeHeaderView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import DesignSystem

/// 홈 화면 최상단 GNB 위 헤더 (PicKé 로고 + 알림 아이콘).
struct HomeHeaderView: View {
  var hasUnread: Bool = false
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
          .overlay(alignment: .topTrailing) {
            if hasUnread {
              Circle()
                .fill(.errorDefault)
                .frame(width: 6, height: 6)
                .offset(x: 1, y: -1)
            }
          }
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 8)
    .frame(height: 56)
    .background(Color.beige50)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }
}
