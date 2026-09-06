//
//  PickeEmptyStateView.swift
//  DesignSystem
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
        .pretendardFont(.bodyMedium)
        .foregroundStyle(.gray300)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
