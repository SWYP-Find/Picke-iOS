//
//  CommentReplySkeletonView.swift
//  Chat
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

import PickeDesignKit

/// Android `CommentSkeleton` — 원본 카드(본문 2줄) → "답글" 헤더 → 카드 4개(각각 아래 구분선).
struct CommentReplySkeletonView: View {
  var body: some View {
    VStack(spacing: 0) {
      card(showsSecondLine: true)
      SkeletonView.line(width: 70, height: 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.surfaceBeigeSubtle)
      ForEach(0 ..< 4, id: \.self) { _ in
        card(showsSecondLine: false)
          .overlay(alignment: .bottom) {
            PickeDivider(.borderBeigeDefault)
          }
      }
    }
    .allowsHitTesting(false)
  }

  @ViewBuilder
  private func card(showsSecondLine: Bool) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        SkeletonView.beige(.circle)
          .frame(width: 32, height: 32)
        VStack(alignment: .leading, spacing: 4) {
          SkeletonView.line(width: 48, height: 16)
          SkeletonView.line(width: 40, height: 12)
        }
        Spacer(minLength: 0)
      }
      SkeletonView.line(width: 70, height: 20)
        .padding(.top, 8)
      SkeletonView.line(width: 260, height: 16)
        .padding(.top, 12)
      if showsSecondLine {
        SkeletonView.line(width: 180, height: 16)
          .padding(.top, 4)
      }
      SkeletonView.line(width: 36, height: 16)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.top, 12)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.surfaceBeigeDefault)
  }
}
