//
//  PickeEmptyStateView.swift
//  DesignSystem
//
//  공통 빈 상태 뷰 — noDataLogo + 안내 문구. (배틀 모듈 emptyState 패턴 공통화)
//

import SwiftUI

public struct PickeEmptyStateView: View {
  private let message: String
  private let imageAsset: ImageAsset
  private let imageSize: CGSize

  public init(
    message: String,
    imageAsset: ImageAsset = .noDataLogo,
    imageSize: CGSize = CGSize(width: 135, height: 90)
  ) {
    self.message = message
    self.imageAsset = imageAsset
    self.imageSize = imageSize
  }

  public var body: some View {
    VStack(spacing: 8) {
      Image(asset: imageAsset)
        .resizable()
        .scaledToFit()
        .frame(width: imageSize.width, height: imageSize.height)

      Text(message)
        .pretendardCustomFont(textStyle: .bodyMedium)
        .foregroundStyle(.beige300)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
