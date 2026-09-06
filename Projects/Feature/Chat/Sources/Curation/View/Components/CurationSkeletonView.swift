//
//  CurationSkeletonView.swift
//  Chat
//

import SwiftUI

import PickeDesignKit

struct CurationSkeletonView: View {
  var count: Int = 4

  var body: some View {
    VStack(spacing: 16) {
      ForEach(0 ..< count, id: \.self) { _ in
        card()
      }
    }
  }

  @ViewBuilder
  private func card() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      // meta
      HStack(spacing: 10) {
        SkeletonView(.round(cornerRadius: .radiusDefault)).frame(width: 44, height: 18)
        Spacer()
        SkeletonView(.round(cornerRadius: 4)).frame(width: 36, height: 12)
        SkeletonView(.round(cornerRadius: 4)).frame(width: 36, height: 12)
      }
      VStack(alignment: .leading, spacing: 4) {
        SkeletonView(.round(cornerRadius: 4)).frame(maxWidth: .infinity).frame(height: 14)
        SkeletonView(.round(cornerRadius: 4)).frame(width: 220, height: 12)
      }
      // versus
      HStack(spacing: 8) {
        optionPlaceholder()
        SkeletonView(.round(cornerRadius: 12)).frame(width: 24, height: 24)
        optionPlaceholder()
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(.beige50, border: .beige600)
  }

  @ViewBuilder
  private func optionPlaceholder() -> some View {
    HStack(spacing: 4) {
      SkeletonView(.round(cornerRadius: 20)).frame(width: 40, height: 40)
      VStack(spacing: 2) {
        SkeletonView(.round(cornerRadius: 4)).frame(width: 44, height: 11)
        SkeletonView(.round(cornerRadius: 4)).frame(width: 30, height: 10)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(8)
    .pickeCard(.beige300, border: .beige600)
  }
}
