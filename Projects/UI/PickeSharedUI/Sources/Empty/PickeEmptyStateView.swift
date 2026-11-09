//
//  PickeEmptyStateView.swift
//  PickeSharedUI
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import PickeDesignKit

public struct PickeEmptyStateView: View {
  private let message: String
  private let imageAsset: ImageAsset
  private let imageSize: CGSize

  public init(
    message: String,
    imageAsset: ImageAsset = .appLogo,
    imageSize: CGSize = CGSize(width: 160, height: 120)
  ) {
    self.message = message
    self.imageAsset = imageAsset
    self.imageSize = imageSize
  }

  /// Android `PickeEmptyState` — 로고 160×120(`borderBeigeDefault` 색), 간격 16, 14 Regular `beige800`, 가운데 정렬.
  public var body: some View {
    VStack(spacing: 16) {
      Image(asset: imageAsset)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .foregroundStyle(.borderBeigeDefault)
        .frame(width: imageSize.width, height: imageSize.height)
        .accessibilityLabel("빈 화면 로고")

      Text(message)
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.beige800)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
