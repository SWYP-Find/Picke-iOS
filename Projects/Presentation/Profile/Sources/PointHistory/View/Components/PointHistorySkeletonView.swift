//
//  PointHistorySkeletonView.swift
//  Profile
//

import SwiftUI

import PickeDesignKit

struct PointHistorySkeletonView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        ForEach(0 ..< 8, id: \.self) { _ in
          HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
              block(width: 80, height: 14)
              block(width: 64, height: 12)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
              block(width: 48, height: 14)
              block(width: 28, height: 12)
            }
          }
          .padding(16)
          .frame(maxWidth: .infinity)
          .roundedBackground(.beige50, radius: 8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(.beige600, lineWidth: 1)
          )
        }
      }
      .padding(.vertical, 20)
      .padding(.horizontal, 16)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func block(width: CGFloat, height: CGFloat) -> some View {
    SkeletonBlock(cornerRadius: 4, tone: .light)
      .frame(width: width, height: height)
  }
}
