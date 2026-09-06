//
//  BattleRecordSkeletonView.swift
//  Profile
//

import SwiftUI

import PickeDesignKit

struct BattleRecordSkeletonView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        ForEach(0 ..< 6, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
              block(width: 40, height: 18)
              block(width: 150, height: 16)
            }
            block(width: nil, maxWidth: true, height: 32)
            block(width: 72, height: 12)
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .pickeCard(
            .beige50,
            border: .beige600,
            radius: 8
          )
        }
      }
      .padding(.vertical, 20)
      .padding(.horizontal, 16)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func block(
    width: CGFloat?,
    maxWidth: Bool = false,
    height: CGFloat
  ) -> some View {
    SkeletonView(.round(cornerRadius: 4))
      .frame(width: width)
      .frame(maxWidth: maxWidth ? .infinity : nil)
      .frame(height: height)
  }
}
