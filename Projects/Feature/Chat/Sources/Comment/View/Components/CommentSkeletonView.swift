//
//  CommentSkeletonView.swift
//  Chat
//

import SwiftUI

import PickeDesignKit

struct CommentSkeletonView: View {
  var count: Int = 3

  var body: some View {
    VStack(spacing: 12) {
      ForEach(0 ..< count, id: \.self) { _ in
        card()
      }
    }
  }

  @ViewBuilder
  private func card() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        SkeletonView(.round(cornerRadius: 14))
          .frame(width: 28, height: 28)
        VStack(alignment: .leading, spacing: 4) {
          SkeletonView(.round(cornerRadius: 4)).frame(width: 80, height: 12)
          SkeletonView(.round(cornerRadius: 4)).frame(width: 48, height: 10)
        }
        Spacer()
      }
      SkeletonView(.round(cornerRadius: 4)).frame(maxWidth: .infinity).frame(height: 12)
      SkeletonView(.round(cornerRadius: 4)).frame(width: 200, height: 12)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(.beige50, border: .beige600)
  }
}
