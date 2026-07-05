//
//  HomeHeaderView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem

/// 홈 화면 최상단 GNB 위 헤더 (PicKé 로고 + 알림 아이콘).
struct HomeHeaderView: View {
  /// 종 빨간점 — 미읽음 플래그를 @Shared(appStorage)로 뷰에서 직접 관찰해 즉시 반응 갱신.
  /// (store.hasUnreadNotification 로 전달받으면 타 화면의 @Shared 변경이 뷰 재렌더를 트리거하지 않아 점이 stale 하게 남던 문제 방지)
  @Shared(.appStorage("HasUnreadNotification")) private var hasUnread = false
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
    .background(.beige50)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.beige600)
        .frame(height: 1)
    }
  }
}
