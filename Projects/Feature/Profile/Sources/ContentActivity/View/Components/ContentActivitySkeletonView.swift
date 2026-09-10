//
//  ContentActivitySkeletonView.swift
//  Profile
//

import SwiftUI

import PickeDesignKit

struct ContentActivitySkeletonView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        ForEach(0 ..< 5, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
              SkeletonView(.round(cornerRadius: 18))
                .frame(width: 36, height: 36)
              VStack(alignment: .leading, spacing: 4) {
                block(width: 120, height: 14)
                block(width: 50, height: 10)
              }
              Spacer(minLength: 0)
            }
            block(width: nil, maxWidth: true, height: 36)
            HStack {
              Spacer()
              block(width: 40, height: 12)
            }
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
