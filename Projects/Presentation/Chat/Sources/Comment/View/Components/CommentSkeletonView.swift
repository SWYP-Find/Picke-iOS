//
//  CommentSkeletonView.swift
//  Chat
//
//  댓글(관점) 리스트 로딩 placeholder.
//  초기 로드 / 정렬·필터 전환 / 등록 후 갱신 시 노출된다.
//

import SwiftUI

import DesignSystem

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
        SkeletonView(cornerRadius: 14)
          .frame(width: 28, height: 28)
        VStack(alignment: .leading, spacing: 4) {
          SkeletonView(cornerRadius: 4).frame(width: 80, height: 12)
          SkeletonView(cornerRadius: 4).frame(width: 48, height: 10)
        }
        Spacer()
      }
      SkeletonView(cornerRadius: 4).frame(maxWidth: .infinity).frame(height: 12)
      SkeletonView(cornerRadius: 4).frame(width: 200, height: 12)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: .radiusDefault))
    .overlay {
      RoundedRectangle(cornerRadius: .radiusDefault).stroke(.beige600, lineWidth: 1)
    }
  }
}
