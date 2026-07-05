//
//  ExploreSkeletonView.swift
//  Hifi
//
//  탐색(Hi-Fi) 리스트 로딩 placeholder. 초기 로드 / 카테고리·정렬 전환 시 노출.
//

import SwiftUI

import DesignSystem

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
      SkeletonView(cornerRadius: .radiusDefault)
        .frame(width: 76, height: 76)

      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 6) {
            SkeletonView(cornerRadius: .radiusDefault).frame(width: 44, height: 18)
            SkeletonView(cornerRadius: 4).frame(maxWidth: .infinity).frame(height: 14)
          }
          SkeletonView(cornerRadius: 4).frame(maxWidth: .infinity).frame(height: 12)
          SkeletonView(cornerRadius: 4).frame(width: 180, height: 12)
        }

        HStack(spacing: 6) {
          Spacer()
          SkeletonView(cornerRadius: 4).frame(width: 36, height: 12)
          SkeletonView(cornerRadius: 4).frame(width: 44, height: 12)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.beige50)
    .overlay(alignment: .bottom) {
      Rectangle().fill(.beige600).frame(height: 1)
    }
  }
}
