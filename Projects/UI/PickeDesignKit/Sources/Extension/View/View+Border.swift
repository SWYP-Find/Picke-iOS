//
//  View+Border.swift
//  PickeDesignKit
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

public extension View {
  /// 라운드 테두리. `insideBorder`는 외곽선을 도형 내부에 그린다.
  func roundedBorder(
    _ color: Color,
    lineWidth: CGFloat = 1,
    radius: CGFloat = .radiusDefault,
    insideBorder: Bool = false
  ) -> some View {
    overlay {
      if insideBorder {
        RoundedRectangle(cornerRadius: radius)
          .strokeBorder(color, lineWidth: lineWidth)
      } else {
        RoundedRectangle(cornerRadius: radius)
          .stroke(color, lineWidth: lineWidth)
      }
    }
  }

  /// 카드 외형 — 라운드 배경 + 테두리.
  func pickeCard(
    _ background: Color = .cardBaseBackgroundDefault,
    border: Color = .borderBeigeDefault,
    lineWidth: CGFloat = 1,
    radius: CGFloat = .radiusDefault,
    insideBorder: Bool = false
  ) -> some View {
    roundedBackground(background, radius: radius)
      .roundedBorder(
        border,
        lineWidth: lineWidth,
        radius: radius,
        insideBorder: insideBorder
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
