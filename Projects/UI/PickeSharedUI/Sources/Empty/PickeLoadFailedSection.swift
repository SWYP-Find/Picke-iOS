//
//  PickeLoadFailedSection.swift
//  PickeSharedUI
//
//  Created by Picke on 11/10/26.
//

import PickeDesignKit
import SwiftUI

/// Android `PickeLoadFailedSection` — 조회에 실패한 영역 자리에 그리는 공용 표시.
/// 테두리 1 `borderBeigeDefault` radius 2, 안쪽 16, 경고 아이콘 16 + "정보를 불러오지 못했어요" 14 Regular `textMuted`.
public struct PickeLoadFailedSection: View {
  public init() {}

  public var body: some View {
    HStack(spacing: 8) {
      Image(asset: .warning)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
      Text("정보를 불러오지 못했어요")
        .pretendardFont(.bodyMedium)
    }
    .foregroundStyle(.textMuted)
    .frame(maxWidth: .infinity)
    .padding(16)
    .roundedBorder(
      .borderBeigeDefault,
      lineWidth: 1,
      radius: .radiusDefault,
      insideBorder: true
    )
  }
}
