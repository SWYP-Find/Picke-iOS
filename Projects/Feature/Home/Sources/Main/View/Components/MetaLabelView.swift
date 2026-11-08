//
//  MetaLabelView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import PickeDesignKit
import SwiftUI

/// 시계·눈 메타 정보 — Android `ic_clock`/`ic_eye` 아이콘(fit) + 12 Medium 텍스트.
/// 카드마다 아이콘 크기·간격·색이 달라(Android 시안) 호출부에서 넘긴다.
struct MetaLabelView: View {
  let asset: ImageAsset
  let text: String
  var iconSize: CGFloat = 12
  var spacing: CGFloat = 2
  var iconColor: Color = .gray400
  var textColor: Color = .gray400

  var body: some View {
    HStack(spacing: spacing) {
      Image(asset: asset)
        .resizable()
        .scaledToFit()
        .frame(width: iconSize, height: iconSize)
        .foregroundStyle(iconColor)
        .accessibilityHidden(true)
      Text(text)
        .pretendardFont(.labelSmall)
        .foregroundStyle(textColor)
    }
  }
}
