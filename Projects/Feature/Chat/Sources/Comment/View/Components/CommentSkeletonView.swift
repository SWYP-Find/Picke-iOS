//
//  CommentSkeletonView.swift
//  Chat
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import PickeDesignKit

/// Android `PerspectiveListSkeleton` — 카드 4개, 가로 16·세로 12, 간격 12.
struct CommentSkeletonView: View {
  var body: some View {
    VStack(spacing: 12) {
      ForEach(0 ..< 4, id: \.self) { _ in
        card()
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .allowsHitTesting(false)
  }

  @ViewBuilder
  private func card() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        SkeletonView.beige(.circle)
          .frame(width: 32, height: 32)
        VStack(alignment: .leading, spacing: 4) {
          SkeletonView.line(width: 40, height: 16)
          SkeletonView.line(width: 50, height: 12)
        }
        Spacer(minLength: 0)
      }
      SkeletonView.line(width: 70, height: 20)
        .padding(.top, 8)
      SkeletonView.line(width: 260, height: 16)
        .padding(.top, 12)
      SkeletonView.line(width: 200, height: 16)
        .padding(.top, 4)
      HStack(spacing: 0) {
        SkeletonView.line(width: 40, height: 14)
        Spacer(minLength: 0)
        SkeletonView.line(width: 24, height: 14)
        SkeletonView.line(width: 24, height: 14)
          .padding(.leading, 12)
      }
      .padding(.top, 12)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickeCard(
      .surfaceBeigeDefault,
      border: .borderBeigeDefault,
      insideBorder: true
    )
  }
}
