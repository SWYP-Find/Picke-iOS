//
//  PickeDivider.swift
//  PickeDesignKit
//

import SwiftUI

/// 가로 구분선. 흐름 안에 높이를 차지하며 놓일 때 쓴다.
/// 레이아웃에 영향 없이 얹기만 할 때는 `bottomDivider` / `topDivider` 를 쓴다.
public struct PickeDivider: View {
  private let color: Color
  private let height: CGFloat

  public init(_ color: Color = .borderBeigeDefault, height: CGFloat = 1) {
    self.color = color
    self.height = height
  }

  public var body: some View {
    Rectangle()
      .fill(color)
      .frame(height: height)
  }
}
