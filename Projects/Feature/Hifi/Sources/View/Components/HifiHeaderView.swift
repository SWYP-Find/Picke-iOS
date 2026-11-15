//
//  HifiHeaderView.swift
//  Hifi
//
//  Created by Picke on 6/4/26.
//

import SwiftUI

import PickeDesignKit

/// Android `PickeTopAppBar(showLogo = true)` — 높이 48, 로고 63×40 `gray900`, 배경 `backgroundBeige`.
/// Android 는 알림 버튼을 숨겨 두었으므로 로고만 둔다.
struct HifiHeaderView: View {
  var body: some View {
    HStack(spacing: 0) {
      Image(asset: .appLogo)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .foregroundStyle(.gray900)
        .frame(width: 63, height: 40)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(.bgBeige)
  }
}
