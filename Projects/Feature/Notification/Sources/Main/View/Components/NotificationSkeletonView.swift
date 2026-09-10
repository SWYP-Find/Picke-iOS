//
//  NotificationSkeletonView.swift
//  Notification
//

import SwiftUI

import PickeDesignKit

struct NotificationSkeletonView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        ForEach(0 ..< 7, id: \.self) { _ in
          HStack(alignment: .center, spacing: 16) {
            SkeletonView(.round(cornerRadius: 12))
              .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {
              HStack {
                block(width: 120, height: 12)
                Spacer(minLength: 0)
                block(width: 40, height: 12)
              }
              block(width: nil, maxWidth: true, height: 16)
            }
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .pickeCard(.beige50, border: .beige600)
        }
      }
      .padding(.top, 8)
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
