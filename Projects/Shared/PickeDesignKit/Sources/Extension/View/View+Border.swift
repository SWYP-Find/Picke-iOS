//
//  View+Border.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// `.overlay(RoundedRectangle(cornerRadius:).stroke(color, lineWidth:))` 축약.
  func roundedBorder(
    _ color: Color,
    lineWidth: CGFloat = 1,
    radius: CGFloat = .radiusDefault
  ) -> some View {
    overlay(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: lineWidth))
  }

  /// 카드 외형 — 라운드 배경 + 테두리.
  func pickeCard(
    _ background: Color = .cardBaseBackgroundDefault,
    border: Color = .borderBeigeDefault,
    lineWidth: CGFloat = 1,
    radius: CGFloat = .radiusDefault
  ) -> some View {
    roundedBackground(background, radius: radius)
      .roundedBorder(
        border,
        lineWidth: lineWidth,
        radius: radius
      )
  }

  /// 하단 구분선을 덧입힌다. 레이아웃 높이에 영향을 주지 않는다.
  func bottomDivider(_ color: Color = .borderBeigeDefault, height: CGFloat = 1) -> some View {
    overlay(alignment: .bottom) {
      PickeDivider(color, height: height)
    }
  }

  /// 상단 구분선을 덧입힌다. 레이아웃 높이에 영향을 주지 않는다.
  func topDivider(_ color: Color = .borderBeigeDefault, height: CGFloat = 1) -> some View {
    overlay(alignment: .top) {
      PickeDivider(color, height: height)
    }
  }
}
