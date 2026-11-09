//
//  CommentHeaderSkeletonView.swift
//  Chat
//
//  Created by Picke on 11/10/26.
//

import SwiftUI

import PickeDesignKit

/// Android `PerspectiveHeaderSkeleton` + `PerspectiveTabBarSkeleton` — 첫 조회 중 통계·탭 자리.
struct CommentHeaderSkeletonView: View {
  var body: some View {
    VStack(spacing: 0) {
      statsRow()
      SkeletonView.line(width: 64, height: 20)
        .frame(maxWidth: .infinity)
        .padding(16)
        .overlay(alignment: .bottom) {
          Rectangle()
            .fill(.borderBeigeDefault)
            .frame(height: 2)
        }
    }
    .allowsHitTesting(false)
  }

  @ViewBuilder
  private func statsRow() -> some View {
    HStack(spacing: 8) {
      sideColumn()
      VStack(spacing: 24) {
        SkeletonView.line(width: 96, height: 20)
        SkeletonView.beige(.round(cornerRadius: 3))
          .frame(height: 6)
      }
      .frame(maxWidth: .infinity)
      sideColumn()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
  }

  @ViewBuilder
  private func sideColumn() -> some View {
    VStack(spacing: 0) {
      SkeletonView.beige(.circle)
        .frame(width: 40, height: 40)
      SkeletonView.line(width: 40, height: 14)
        .padding(.top, 2)
      SkeletonView.line(width: 28, height: 16)
    }
    .frame(width: 64)
  }
}
