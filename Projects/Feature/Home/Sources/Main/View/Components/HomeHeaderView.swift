//
//  HomeHeaderView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import PickeDesignKit
import SwiftUI

/// 홈 상단 바 — Android `PickeTopAppBar`(로고 + 알림 액션) 시안. 높이 48, 아래 구분선 없음.
struct HomeHeaderView: View {
  let hasUnread: Bool
  /// 첫 로딩 중이거나 미읽음 조회 전이면 종 대신 shimmer 원을 그린다.
  let isLoading: Bool
  let onNotificationTapped: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      logo
      Spacer(minLength: 0)
      notificationAction()
    }
    .padding(.leading, 16)
    .padding(.trailing, 4)
    .frame(height: 48)
    .background(.bgBeige)
  }
}

extension HomeHeaderView {
  private var logo: some View {
    Image(asset: .appLogo)
      .resizable()
      .frame(width: 63, height: 40)
      .accessibilityLabel("Picke 로고")
  }

  /// Android `IconButton`(48 터치 영역) 안 20pt 아이콘, 로딩 중엔 같은 자리 24pt 원.
  @ViewBuilder
  private func notificationAction() -> some View {
    if isLoading {
      SkeletonView(
        .circle,
        base: .surfaceBeigeStrong,
        highlight: .surfaceBeigeDefault
      )
      .frame(width: 24, height: 24)
      .frame(width: 48, height: 48)
    } else {
      Button(action: onNotificationTapped) {
        bellIcon
          .frame(width: 48, height: 48)
          .contentShape(Rectangle())
      }
      .accessibilityLabel("알림")
    }
  }

  /// Material3 소형 배지(6pt)는 아이콘 오른쪽 끝에서 6 안쪽·위쪽 0에 놓이고, Android 가 offset(4, −4)을 더 준다.
  private var bellIcon: some View {
    Image(asset: .alarm)
      .resizable()
      .frame(width: 20, height: 20)
      .overlay(alignment: .topLeading) {
        if hasUnread {
          Circle()
            .fill(.primary500)
            .frame(width: 6, height: 6)
            .offset(x: 20 - 6 + 4, y: -4)
        }
      }
  }
}
