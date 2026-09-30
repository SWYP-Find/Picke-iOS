//
//  ClassMenuCard.swift
//  Class
//

import SwiftUI

import PickeDesignKit

/// 클래스 인트로의 진입 카드 (참여하기 / 내 클래스).
struct ClassMenuCard: View {
  let title: String
  let description: String
  let image: ImageAsset
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack(alignment: .bottomTrailing) {
        Image(asset: image)
          .resizable()
          .scaledToFit()
          .frame(width: 96, height: 96)
          .offset(x: 12, y: 12)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .pretendardFont(family: .SemiBold, size: 16)
            .foregroundStyle(.white)

          Text(description)
            .pretendardFont(family: .Regular, size: 13)
            .foregroundStyle(.gray300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .padding(16)
      .frame(maxWidth: .infinity)
      .frame(height: 118)
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
