//
//  ClassMenuCard.swift
//  Class
//

import PickeDesignKit
import SwiftUI

/// 클래스 인트로의 진입 카드 (참여하기 / 내 클래스).
struct ClassMenuCard: View {
  let title: String
  let description: String
  let image: ImageAsset
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .pretendardFont(.headingMedium)
          .foregroundStyle(.beige50)

        Text(description)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .topLeading)
      .frame(height: 118, alignment: .top)
      .background(alignment: .topLeading) {
        Image(asset: image)
          .resizable()
          .scaledToFit()
          .frame(width: 130, height: 130)
          .offset(x: 59, y: 38)
      }
      .background(.gray700, in: RoundedRectangle(cornerRadius: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 2)
          .stroke(.gray800, lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    .buttonStyle(.plain)
  }
}
