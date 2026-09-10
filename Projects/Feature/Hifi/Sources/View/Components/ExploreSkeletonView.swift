//
//  ExploreSkeletonView.swift
//  Hifi
//

import SwiftUI

import PickeDesignKit

struct ExploreSkeletonView: View {
  var count: Int = 6

  var body: some View {
    LazyVStack(spacing: 0) {
      ForEach(0 ..< count, id: \.self) { _ in
        row()
      }
    }
  }

  @ViewBuilder
  private func row() -> some View {
    HStack(alignment: .center, spacing: 8) {
      SkeletonView(.round(cornerRadius: .radiusDefault))
        .frame(width: 76, height: 76)

      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 6) {
            SkeletonView(.round(cornerRadius: .radiusDefault)).frame(width: 44, height: 18)
            SkeletonView(.round(cornerRadius: 4)).frame(maxWidth: .infinity).frame(height: 14)
          }
          SkeletonView(.round(cornerRadius: 4)).frame(maxWidth: .infinity).frame(height: 12)
          SkeletonView(.round(cornerRadius: 4)).frame(width: 180, height: 12)
        }

        HStack(spacing: 6) {
          Spacer()
          SkeletonView(.round(cornerRadius: 4)).frame(width: 36, height: 12)
          SkeletonView(.round(cornerRadius: 4)).frame(width: 44, height: 12)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.beige50)
    .bottomDivider(.beige600)
  }
}
