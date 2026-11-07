//
//  MetaLabelView.swift
//  Home
//
//  Created by Picke on 5/15/26.
//

import SwiftUI

import PickeDesignKit

/// 시계/눈 같은 메타 정보를 SF Symbol + 12pt 텍스트로 표시.
struct MetaLabelView: View {
  let systemImage: String
  let text: String

  var body: some View {
    HStack(spacing: 2) {
      Image(systemName: systemImage)
        .resizable().scaledToFit()
        .frame(width: 12, height: 12)
        .foregroundStyle(.neutral300)
      Text(text)
        .pretendardFont(.medium11)
        .foregroundStyle(.neutral300)
    }
  }
}
