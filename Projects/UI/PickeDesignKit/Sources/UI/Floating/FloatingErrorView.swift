//
//  FloatingErrorView.swift
//  PickeDesignKit
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

/// Android `PickeErrorBanner` — `errorDefault` 면, radius 8, 그림자 4, 안쪽 16/12, 경고 아이콘 + 14 SemiBold `beige50`.
public struct FloatingErrorView: View {
  private let message: String

  public init(message: String) {
    self.message = message
  }

  public var body: some View {
    HStack(spacing: 8) {
      Image(asset: .warning)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .foregroundStyle(.beige50)
        .frame(width: 18.8, height: 16.75)

      Text(message)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.beige50)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .roundedBackground(.errorDefault, radius: 8)
    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
  }
}
