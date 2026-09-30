//
//  PickeTabItemLabel.swift
//  PickeSharedUI
//

import SwiftUI

import PickeDesignKit

/// 탭바 아이템 라벨 — 타이틀 + 24pt 템플릿 아이콘.
public struct PickeTabItemLabel: View {
  private let title: String
  private let icon: ImageAsset
  private let tag: Int

  public init(
    title: String,
    icon: ImageAsset,
    tag: Int
  ) {
    self.title = title
    self.icon = icon
    self.tag = tag
  }

  public var body: some View {
    Label {
      Text(title)
        .pretendardFont(.labelSmall)
    } icon: {
      Image(asset: icon)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
    }
    .accessibilityIdentifier("tab.\(tag)")
  }
}
