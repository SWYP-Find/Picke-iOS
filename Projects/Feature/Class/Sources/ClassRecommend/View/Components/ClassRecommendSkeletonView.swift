//
//  ClassRecommendSkeletonView.swift
//  Class
//

import PickeDesignKit
import SwiftUI

/// 추천 결과 로딩 자리표시자. 결과 제목 + `ClassBattleListCard` 와 같은 자리에 블록을 둔다.
struct ClassRecommendSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      bar(width: 76, height: 20)

      ForEach(0 ..< 3, id: \.self) { _ in
        card()
      }
    }
    .allowsHitTesting(false)
  }
}

private extension ClassRecommendSkeletonView {
  @ViewBuilder
  func card() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 12) {
        metaRow()
        titleSection()
      }
      versusRow()
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(.beige50, border: .beige600)
  }

  @ViewBuilder
  func metaRow() -> some View {
    HStack(spacing: 10) {
      bar(width: 41, height: 21)
      Spacer(minLength: 0)
      bar(width: 36, height: 17)
      bar(width: 60, height: 17)
      SkeletonView(.round(cornerRadius: 10))
        .frame(width: 20, height: 20)
    }
  }

  @ViewBuilder
  func titleSection() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      bar(width: 200, height: 18)
      bar(width: 280, height: 17)
    }
  }

  @ViewBuilder
  func versusRow() -> some View {
    HStack(spacing: 8) {
      SkeletonView(.round(cornerRadius: 2))
        .frame(height: 58)
      SkeletonView(.round(cornerRadius: 12))
        .frame(width: 24, height: 24)
      SkeletonView(.round(cornerRadius: 2))
        .frame(height: 58)
    }
  }

  func bar(
    width: CGFloat,
    height: CGFloat
  ) -> some View {
    SkeletonView(.round(cornerRadius: 2))
      .frame(width: width, height: height)
  }
}
